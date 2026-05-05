import Foundation
import SwiftUI
import Observation

@Observable
final class AppState {
    private let authService = AuthService()
    private let walletSessionService = WalletSessionService()
    private let blockchainService = BlockchainService()
    let networkConfig: NetworkConfig = .baseSepolia

    // MARK: - Auth state
    var isLoggedIn: Bool = false
    var userName: String = ""
    var userEmail: String = ""
    var walletAddress: String = ""
    var walletProviderLabel: String = ""
    var walletBalanceUSDC: Double = 124.50
    var hasBiometricAccess: Bool = true

    // MARK: - Navigation state
    var userRole: UserRole = .none
    var hasCompletedOnboarding: Bool = false

    // Beneficiary state
    var quotaResult: QuotaResult? = nil
    var activeProject: SolarProject? = nil
    var paymentHistory: [Payment] = Payment.mockPayments
    var ownershipPct: Double = 0.34

    // Investor state
    var projects: [SolarProject] = SolarProject.mockProjects
    var yieldHistory: [YieldEntry] = YieldEntry.mockYields
    var investedProjects: [SolarProject] = Array(SolarProject.mockProjects.prefix(2))

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
            activeProject = SolarProject.mockProjects[0]
        } catch {
            transactionState = .error(message: error.localizedDescription)
        }
    }

    func purchaseTokens(montoUSD: Double) async {
        transactionState = .processing
        do {
            let hash = try await blockchainService.purchaseTokens()
            transactionState = .purchaseSuccess(txHash: hash)
        } catch {
            transactionState = .error(message: error.localizedDescription)
        }
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
        } catch {
            transactionState = .error(message: error.localizedDescription)
        }
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
    }

    func register(name: String, email: String) async throws {
        let session = try await authService.register(name: name, email: email)
        let wallet = try await walletSessionService.createOrRestoreWallet(email: session.email)
        userName = session.fullName
        userEmail = session.email
        walletAddress = wallet.address
        walletProviderLabel = wallet.providerName
        isLoggedIn = true
    }

    func changeRole() {
        userRole = .none
    }

    func logout() {
        isLoggedIn = false
        userRole = .none
        walletAddress = ""
        walletProviderLabel = ""
        // hasCompletedOnboarding se mantiene: el onboarding solo se muestra una vez
        Task {
            await walletSessionService.logout()
        }
    }
}
