import Foundation
import SwiftUI
import Observation

@Observable
final class AppState {
    private let privyClient: PrivyClient
    private let authService: AuthService
    private let walletSessionService: WalletSessionService
    private let blockchainService = BlockchainService()
    let networkConfig: NetworkConfig = .baseSepolia

    init() {
        let privyClient = PrivyClient()
        self.privyClient = privyClient
        self.authService = AuthService(privyClient: privyClient)
        self.walletSessionService = WalletSessionService(
            provider: PrivyEmbeddedWalletProvider(privyClient: privyClient)
        )
    }

    // MARK: - Auth state
    var isLoggedIn: Bool = false
    var userName: String = ""
    var userEmail: String = ""
    var walletAddress: String = ""
    var walletProviderLabel: String = ""
    var walletBalanceUSDC: Double = 0
    var isLoadingBalance: Bool = false
    var balanceError: String? = nil
    var hasBiometricAccess: Bool = true

    // MARK: - Navigation state
    var userRole: UserRole = .none
    var hasCompletedOnboarding: Bool = false

    // Beneficiary state
    var quotaResult: QuotaResult? = nil
    var activeProject: SolarProject? = nil
    var paymentHistory: [Payment] = []
    var ownershipPct: Double = 0

    // Investor state
    // `projects` es el catalogo publico (datos demo del hackathon); el resto son datos del usuario y arrancan vacios.
    var projects: [SolarProject] = SolarProject.mockProjects
    var yieldHistory: [YieldEntry] = []
    var investments: [Investment] = []
    var investedProjects: [SolarProject] = []

    // Transaction state
    var transactionState: TransactionState = .idle

    // MARK: - Beneficiary actions

    func calculateQuota(consumoMXN: Double, ubicacion: String, plazo: PaymentTerm) -> QuotaResult {
        let consumoKWh = consumoMXN / 3.75
        let horasSol = ubicacion.contains("Mérida") ? 6.1 :
                       ubicacion.contains("Monterrey") ? 5.5 :
                       ubicacion.contains("Guadalajara") ? 5.2 : 4.8
        let coberturaPct = min(0.95, (horasSol * 2.0) / consumoKWh * 100)
        let cuotaMXN = (consumoMXN * 0.72) * (1.0 + (36.0 / Double(plazo.rawValue) - 1) * 0.15)

        let result = QuotaResult(
            cuotaMXN: cuotaMXN.rounded(),
            consumoKWh: consumoKWh.rounded(),
            horasSol: horasSol,
            tamanoPanel: consumoKWh > 300 ? "2.5 kW" : "2 kW",
            coberturaPct: coberturaPct.rounded(),
            plazoMeses: plazo.rawValue,
            rendimientoInversorPct: 9.2,
            confianza: ubicacion.isEmpty ? .baja : .alta,
            explicacion: "Tu cuota es $\(Int(cuotaMXN)) MXN/mes porque consumes \(Int(consumoKWh)) kWh/mes en una zona con \(horasSol)h de sol al día (datos NASA). El panel de \(consumoKWh > 300 ? "2.5" : "2") kW cubrirá el \(Int(coberturaPct))% de tu consumo.",
            ubicacion: ubicacion.isEmpty ? "Tu zona" : ubicacion
        )
        self.quotaResult = result
        return result
    }

    func publishProject() async {
        transactionState = .creatingContract
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        transactionState = .mintingTokens
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        transactionState = .confirming
        do {
            let hash = try await blockchainService.publishProject()
            transactionState = .success(txHash: hash)
            activeProject = makeFreshProject(txHash: hash)
        } catch {
            transactionState = .error(message: error.localizedDescription)
        }
    }

    /// Construye el `SolarProject` recien publicado a partir del `quotaResult` real del beneficiario.
    /// Inicia con 0% financiado y plazo completo: aun no hay inversores ni cuotas pagadas.
    private func makeFreshProject(txHash: String) -> SolarProject {
        let result = quotaResult
        let plazo = result?.plazoMeses ?? 36
        let totalMXN = result?.montoTotalMXN ?? 30_000
        let totalUSDC = totalMXN / 17.5
        let ciudadCompleta = result?.ubicacion ?? "Tu zona"
        let parts = ciudadCompleta.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let ciudad = parts.first ?? ciudadCompleta
        let estado = parts.count > 1 ? parts[1] : "MX"

        return SolarProject(
            id: UUID(),
            ciudad: String(ciudad),
            estado: String(estado),
            rendimientoAnualPct: result?.rendimientoInversorPct ?? 9.0,
            plazoTotalMeses: plazo,
            mesesRestantes: plazo,
            porcentajeFinanciado: 0,
            co2ToneladasAnio: 1.2,
            kwhGeneradosAnio: (result?.consumoKWh ?? 250) * 12,
            montoMinUSD: 1,
            montoTotalUSD: totalUSDC,
            contractAddress: txHash,
            status: .open,
            beneficiario: userName.isEmpty ? "Beneficiario" : userName
        )
    }

    func purchaseTokens(montoUSD: Double, project: SolarProject? = nil) async {
        transactionState = .processing
        do {
            let hash = try await blockchainService.purchaseTokens()
            if let project {
                let investment = Investment(
                    id: UUID(),
                    projectId: project.id,
                    montoUSDC: montoUSD,
                    fecha: Date(),
                    txHash: hash
                )
                investments.insert(investment, at: 0)
                if !investedProjects.contains(where: { $0.id == project.id }) {
                    investedProjects.insert(project, at: 0)
                }
            }
            transactionState = .purchaseSuccess(txHash: hash)
            await refreshWalletBalance()
        } catch {
            transactionState = .error(message: error.localizedDescription)
        }
    }

    /// Suma el monto invertido por el usuario en un proyecto especifico.
    func investedAmount(in projectId: UUID) -> Double {
        investments
            .filter { $0.projectId == projectId }
            .reduce(0) { $0 + $1.montoUSDC }
    }

    /// Total invertido por el usuario en todos los proyectos.
    var totalInvestedUSDC: Double {
        investments.reduce(0) { $0 + $1.montoUSDC }
    }

    func payMonthlyQuota() async {
        transactionState = .processing
        do {
            let hash = try await blockchainService.payMonthlyQuota()
            let newPayment = Payment(
                id: UUID(), fecha: Date(),
                montoMXN: quotaResult?.cuotaMXN ?? 850,
                montoUSDC: (quotaResult?.cuotaUSDC ?? 48.57),
                txHash: hash
            )
            paymentHistory.insert(newPayment, at: 0)
            ownershipPct = min(1.0, ownershipPct + (1.0 / Double(quotaResult?.plazoMeses ?? 36)))
            transactionState = .purchaseSuccess(txHash: hash)
            await refreshWalletBalance()
        } catch {
            transactionState = .error(message: error.localizedDescription)
        }
    }

    /// Consulta on-chain el balance real de USDC de la wallet del usuario.
    /// Si la wallet aun no esta lista, queda en 0 sin marcar error.
    @MainActor
    func refreshWalletBalance() async {
        guard !walletAddress.isEmpty else {
            walletBalanceUSDC = 0
            balanceError = nil
            return
        }
        isLoadingBalance = true
        balanceError = nil
        do {
            let value = try await blockchainService.fetchUSDCBalance(address: walletAddress)
            walletBalanceUSDC = value
        } catch {
            balanceError = error.localizedDescription
            #if DEBUG
            print("⚠️ [Sunstake] No se pudo leer el balance USDC: \(error.localizedDescription)")
            #endif
        }
        isLoadingBalance = false
    }

    func resetTransaction() {
        transactionState = .idle
    }

    // MARK: - Auth actions

    func sendAccessCode(email: String) async throws {
        try await authService.sendOTP(to: email)
    }

    func login(email: String, otp: String) async throws {
        let session = try await authService.loginWithOTP(email: email, otp: otp)
        let wallet = try await walletSessionService.createOrRestoreWallet(email: session.email)
        userEmail = session.email
        userName = session.fullName
        walletAddress = wallet.address
        walletProviderLabel = wallet.providerName
        isLoggedIn = true
        #if DEBUG
        print("✅ [Sunstake] Login OK — email: \(session.email) | wallet: \(wallet.address) | provider: \(wallet.providerName)")
        #endif
        await refreshWalletBalance()
    }

    func register(name: String, email: String, otp: String) async throws {
        let session = try await authService.register(name: name, email: email, otp: otp)
        let wallet = try await walletSessionService.createOrRestoreWallet(email: session.email)
        userName = session.fullName
        userEmail = session.email
        walletAddress = wallet.address
        walletProviderLabel = wallet.providerName
        isLoggedIn = true
        #if DEBUG
        print("✅ [Sunstake] Registro OK — email: \(session.email) | wallet: \(wallet.address) | provider: \(wallet.providerName)")
        #endif
        await refreshWalletBalance()
    }

    func changeRole() {
        userRole = .none
    }

    func logout() {
        isLoggedIn = false
        userRole = .none
        walletAddress = ""
        walletProviderLabel = ""
        walletBalanceUSDC = 0
        balanceError = nil
        // Datos del usuario: limpiar al cerrar sesion (solo `projects` queda como catalogo publico).
        paymentHistory = []
        yieldHistory = []
        investments = []
        investedProjects = []
        activeProject = nil
        ownershipPct = 0
        quotaResult = nil
        // hasCompletedOnboarding se mantiene: el onboarding solo se muestra una vez
        Task {
            await walletSessionService.logout()
        }
    }
}
