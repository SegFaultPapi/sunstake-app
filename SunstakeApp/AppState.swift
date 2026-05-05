import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var userRole: UserRole = .none
    @Published var hasCompletedOnboarding: Bool = false

    // Beneficiary state
    @Published var quotaResult: QuotaResult? = nil
    @Published var activeProject: SolarProject? = nil
    @Published var paymentHistory: [Payment] = Payment.mockPayments
    @Published var ownershipPct: Double = 0.34

    // Investor state
    @Published var projects: [SolarProject] = SolarProject.mockProjects
    @Published var yieldHistory: [YieldEntry] = YieldEntry.mockYields
    @Published var investedProjects: [SolarProject] = Array(SolarProject.mockProjects.prefix(2))

    // Transaction state
    @Published var transactionState: TransactionState = .idle

    // MARK: - Beneficiary actions

    func calculateQuota(consumoMXN: Double, ubicacion: String, plazo: PaymentTerm) -> QuotaResult {
        // Simulates Core ML on-device calculation
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
        try? await Task.sleep(nanoseconds: 800_000_000)
        let hash = "0x\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(40))"
        transactionState = .success(txHash: hash)
        activeProject = SolarProject.mockProjects[0]
    }

    func purchaseTokens(montoUSD: Double) async {
        transactionState = .processing
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        let hash = "0x\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(40))"
        transactionState = .purchaseSuccess(txHash: hash)
    }

    func payMonthlyQuota() async {
        transactionState = .processing
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        let hash = "0x\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(40))"
        let newPayment = Payment(
            id: UUID(), fecha: Date(),
            montoMXN: quotaResult?.cuotaMXN ?? 850,
            montoUSDC: (quotaResult?.cuotaUSDC ?? 48.57),
            txHash: hash
        )
        paymentHistory.insert(newPayment, at: 0)
        ownershipPct = min(1.0, ownershipPct + (1.0 / Double(quotaResult?.plazoMeses ?? 36)))
        transactionState = .purchaseSuccess(txHash: hash)
    }

    func resetTransaction() {
        transactionState = .idle
    }
}
