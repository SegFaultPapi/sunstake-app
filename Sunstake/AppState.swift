import Foundation
import SwiftUI
import Observation

@Observable
final class AppState {
    private let privyClient: PrivyClient
    private let authService: AuthService
    private let walletSessionService: WalletSessionService
    private let blockchainService: BlockchainService

    let networkConfig: NetworkConfig

    init() {
        let nc = NetworkConfig.baseSepolia
        self.networkConfig = nc
        self.blockchainService = BlockchainService(config: nc)
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
    var activeProjects: [SolarProject] = []
    var selectedProjectIndex: Int = 0
    var paymentHistory: [Payment] = []
    var ownershipPct: Double = 0

    var activeProject: SolarProject? { activeProjects.first }
    var selectedProject: SolarProject? {
        activeProjects.indices.contains(selectedProjectIndex) ? activeProjects[selectedProjectIndex] : activeProjects.first
    }

    // Investor state
    // Catalogo del explorador (mocks si la factory esta vacia o falla el RPC).
    var projects: [SolarProject] = SolarProject.mockProjects
    var yieldHistory: [YieldEntry] = []
    var investments: [Investment] = []
    var investedProjects: [SolarProject] = []

    // Transaction state
    var transactionState: TransactionState = .idle

    // Toast notifications
    var activeToast: StatusToast? = nil
    var isShowingToast: Bool = false
    var isRestoringInvestorState: Bool = false
    var investorRestoreFailed: Bool = false

    private func evmSigner() -> PrivyEVMSigner {
        PrivyEVMSigner(privyClient: privyClient, rpcURL: networkConfig.rpcURL.absoluteString)
    }

    /// Sincroniza el listado de proyectos con `SunstakeFactory.getProjects()` en Base Sepolia.
    func refreshProjectCatalogFromChain() async {
        do {
            let onChain = try await blockchainService.fetchSolarProjectsForExplorer()
            projects = onChain.isEmpty ? SolarProject.mockProjects : onChain
        } catch {
            #if DEBUG
            print("[Sunstake] Catalogo on-chain: \(error.localizedDescription)")
            #endif
        }
    }

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
        do {
            guard activeProjects.count < 3 else {
                transactionState = .error(message: "Ya tienes 3 paneles activos, que es el máximo permitido.")
                return
            }
            guard let result = quotaResult else {
                transactionState = .error(message: "No hay una cuota calculada. Vuelve a calcular tu cuota.")
                return
            }
            let ciudadCompleta = result.ubicacion
            let parts = ciudadCompleta.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let ciudad = parts.first ?? ciudadCompleta
            let estado = parts.count > 1 ? parts[1] : "MX"

            transactionState = .confirming
            let blockchainResult = try await blockchainService.publishProject(
                cuotaUSDC: result.cuotaUSDC,
                montoTotalUSDC: result.montoTotalMXN / 17.5,
                plazoMeses: result.plazoMeses,
                rendimientoAnualPct: result.rendimientoInversorPct,
                ciudad: ciudad,
                estado: estado,
                fromAddress: walletAddress,
                signer: evmSigner()
            )
            transactionState = .success(txHash: blockchainResult.txHash)
            activeProjects.append(makeFreshProject(blockchainResult: blockchainResult))
            selectedProjectIndex = activeProjects.count - 1
            await refreshProjectCatalogFromChain()
            await showToast(StatusToast(
                kind: .success,
                title: "¡Proyecto publicado!",
                subtitle: "Ya es visible para todos los inversores.",
                txHash: blockchainResult.txHash
            ), autoDismissAfter: 5)
        } catch {
            transactionState = .error(message: error.localizedDescription)
            await showToast(StatusToast(
                kind: .error,
                title: "Error al publicar",
                subtitle: error.localizedDescription,
                txHash: nil
            ), autoDismissAfter: 6)
        }
    }

    /// Construye el `SolarProject` recien publicado usando direcciones reales emitidas por `SunstakeFactory`.
    private func makeFreshProject(blockchainResult: BlockchainPublishResult) -> SolarProject {
        let result = quotaResult
        let plazo = result?.plazoMeses ?? 36
        let totalMXN = result?.montoTotalMXN ?? 30_000
        let totalUSDC = totalMXN / 17.5
        let ciudadCompleta = result?.ubicacion ?? "Tu zona"
        let parts = ciudadCompleta.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let ciudad = parts.first ?? ciudadCompleta
        let estado = parts.count > 1 ? parts[1] : "MX"

        let ca = BlockchainService.canonicalEVMAddress(blockchainResult.solarProjectAddress)
        let ps = BlockchainService.canonicalEVMAddress(blockchainResult.paymentSplitterAddress)

        return SolarProject(
            id: SolarProject.deterministicId(contractAddress: ca),
            ciudad: ciudad,
            estado: estado,
            rendimientoAnualPct: result?.rendimientoInversorPct ?? 9.0,
            plazoTotalMeses: plazo,
            mesesRestantes: plazo,
            porcentajeFinanciado: 0,
            co2ToneladasAnio: 1.2,
            kwhGeneradosAnio: (result?.consumoKWh ?? 250) * 12,
            montoMinUSD: 1,
            montoTotalUSD: totalUSDC,
            contractAddress: ca,
            paymentSplitterAddress: ps,
            status: .open,
            beneficiario: userName.isEmpty ? "Beneficiario" : userName
        )
    }

    func purchaseTokens(montoUSD: Double, project: SolarProject? = nil) async {
        transactionState = .processing
        do {
            guard let project else {
                transactionState = .error(message: "Selecciona un proyecto valido antes de invertir.")
                return
            }
            guard project.isBackedByOnChainContracts else {
                let msg =
                    "Este listado es de demostracion. En Proyectos, desliza hacia abajo para cargar proyectos reales desde Base Sepolia."
                transactionState = .idle
                await showToast(
                    StatusToast(
                        kind: .info,
                        title: "Inversion no disponible en modo demo",
                        subtitle: msg,
                        txHash: nil
                    ),
                    autoDismissAfter: 7
                )
                return
            }
            // Preflight: refresh balance and abort early if insufficient USDC
            await refreshWalletBalance()
            if balanceError == nil && walletBalanceUSDC < montoUSD {
                let needed = String(format: "%.2f", montoUSD)
                let have   = String(format: "%.2f", walletBalanceUSDC)
                let msg = "Necesitas $\(needed) USDC pero tienes $\(have). Obtén USDC de prueba en staging.aave.com/faucet (selecciona Base Sepolia)."
                transactionState = .error(message: msg)
                await showToast(StatusToast(kind: .error, title: "Saldo insuficiente", subtitle: msg, txHash: nil), autoDismissAfter: 8)
                return
            }

            let hash = try await blockchainService.purchaseTokens(
                solarProjectAddress: project.contractAddress,
                amountUSDC: montoUSD,
                fromAddress: walletAddress,
                signer: evmSigner()
            )
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
            transactionState = .purchaseSuccess(txHash: hash)
            await refreshWalletBalance()
            await showToast(StatusToast(
                kind: .success,
                title: "¡Inversión confirmada!",
                subtitle: "Tu participación está registrada en la red de pagos.",
                txHash: hash
            ), autoDismissAfter: 5)
        } catch is CancellationError {
            transactionState = .idle
        } catch {
            transactionState = .error(message: error.localizedDescription)
            await showToast(StatusToast(
                kind: .error,
                title: "No se pudo completar la inversion",
                subtitle: error.localizedDescription,
                txHash: nil
            ), autoDismissAfter: 6)
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
            guard let splitter = selectedProject?.paymentSplitterAddress, !splitter.isEmpty else {
                transactionState =
                    .error(message: "No hay un proyecto con contrato registrado para pagos. Primero debes publicar tu proyecto desde la app.")
                return
            }
            let cuotaUSD = quotaResult?.cuotaUSDC ?? ((quotaResult?.cuotaMXN ?? 850) / 17.5)
            let hash = try await blockchainService.payMonthlyQuota(
                paymentSplitterAddress: splitter,
                cuotaUSDC: cuotaUSD,
                fromAddress: walletAddress,
                signer: evmSigner()
            )
            let newPayment = Payment(
                id: UUID(), fecha: Date(),
                montoMXN: quotaResult?.cuotaMXN ?? 850,
                montoUSDC: quotaResult?.cuotaUSDC ?? cuotaUSD,
                txHash: hash
            )
            paymentHistory.insert(newPayment, at: 0)
            ownershipPct = min(1.0, ownershipPct + (1.0 / Double(quotaResult?.plazoMeses ?? 36)))
            transactionState = .purchaseSuccess(txHash: hash)
            await refreshWalletBalance()
            await showToast(StatusToast(
                kind: .success,
                title: "Pago enviado",
                subtitle: "Tu cuota mensual fue registrada en la red de pagos.",
                txHash: hash
            ), autoDismissAfter: 5)
        } catch {
            transactionState = .error(message: error.localizedDescription)
            await showToast(StatusToast(
                kind: .error,
                title: "Error al pagar cuota",
                subtitle: error.localizedDescription,
                txHash: nil
            ), autoDismissAfter: 6)
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

    @MainActor
    func showToast(_ toast: StatusToast, autoDismissAfter seconds: Double = 4) {
        activeToast = toast
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isShowingToast = true }
        UINotificationFeedbackGenerator().notificationOccurred(toast.kind == .error ? .error : .success)
        Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            await MainActor.run { dismissToast() }
        }
    }

    @MainActor
    func dismissToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isShowingToast = false }
    }

    /// Restaura `investedProjects` e `investments` desde la chain para el inversor que acaba de iniciar sesion.
    func restoreInvestorStateFromChain() async {
        guard !walletAddress.isEmpty else { return }
        isRestoringInvestorState = true
        investorRestoreFailed = false
        defer { isRestoringInvestorState = false }
        do {
            let pairs = try await blockchainService.fetchInvestedProjectsForWallet(walletAddress: walletAddress)
            for (project, investedUSD) in pairs {
                if !investedProjects.contains(where: { $0.id == project.id }) {
                    investedProjects.append(project)
                }
                if !investments.contains(where: { $0.projectId == project.id }) {
                    investments.append(Investment(
                        id: UUID(),
                        projectId: project.id,
                        montoUSDC: investedUSD,
                        fecha: Date(),
                        txHash: "0x\(project.contractAddress.dropFirst(2).prefix(62))00"
                    ))
                }
            }
        } catch {
            investorRestoreFailed = true
            #if DEBUG
            print("[Sunstake] No se pudo restaurar inversiones: \(error.localizedDescription)")
            #endif
        }
    }

    /// Restaura `activeProject` y `quotaResult` desde la chain para el usuario que acaba de iniciar sesion.
    /// Si no hay proyecto publicado, no hace nada.
    func restoreSessionFromChain() async {
        guard !walletAddress.isEmpty else { return }
        do {
            guard let project = try await blockchainService.fetchActiveProjectForBeneficiary(walletAddress: walletAddress) else {
                return
            }
            if !activeProjects.contains(where: { $0.id == project.id }) {
                activeProjects.append(project)
            }
            let plazo = project.plazoTotalMeses
            let pagados = project.mesesPagados
            ownershipPct = plazo > 0 ? min(1.0, Double(pagados) / Double(plazo)) : 0

            // Reconstruye quotaResult para que payMonthlyQuota() tenga la cuota correcta.
            let cuotaMXN = project.cuotaMensualUSD * 17.5
            let consumoKWh = cuotaMXN / (0.72 * 3.75)
            quotaResult = QuotaResult(
                cuotaMXN: cuotaMXN,
                consumoKWh: consumoKWh,
                horasSol: 5.2,
                tamanoPanel: consumoKWh > 300 ? "2.5 kW" : "2 kW",
                coberturaPct: 0,
                plazoMeses: plazo,
                rendimientoInversorPct: project.rendimientoAnualPct,
                confianza: .media,
                explicacion: "Datos restaurados desde tu contrato en la red de pagos.",
                ubicacion: "\(project.ciudad), \(project.estado)"
            )
        } catch {
            #if DEBUG
            print("[Sunstake] No se pudo restaurar el proyecto activo: \(error.localizedDescription)")
            #endif
        }
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
        await restoreSessionFromChain()
        await restoreInvestorStateFromChain()
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
        await restoreSessionFromChain()
        await restoreInvestorStateFromChain()
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
        // Datos del usuario: limpiar al cerrar sesion (el catalogo vuelve a mocks hasta el proximo RPC).
        paymentHistory = []
        yieldHistory = []
        investments = []
        investedProjects = []
        investorRestoreFailed = false
        activeProjects = []
        selectedProjectIndex = 0
        ownershipPct = 0
        quotaResult = nil
        projects = SolarProject.mockProjects
        // hasCompletedOnboarding se mantiene: el onboarding solo se muestra una vez
        Task {
            await walletSessionService.logout()
        }
    }
}
