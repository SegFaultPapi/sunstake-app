import SwiftUI

struct QuotaResultView: View {
    @EnvironmentObject var appState: AppState
    let result: QuotaResult
    @State private var selectedTerm: PaymentTerm
    @State private var showSummary = false
    @State private var adjustedResult: QuotaResult

    init(result: QuotaResult) {
        self.result = result
        _selectedTerm = State(initialValue: PaymentTerm(rawValue: result.plazoMeses) ?? .thirtySix)
        _adjustedResult = State(initialValue: result)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Confidence bar — HCAI interpretability
                ConfidenceBarView(level: adjustedResult.confianza)

                // Main quota card
                VStack(spacing: 4) {
                    Text("Tu cuota mensual")
                        .font(.sunCaption)
                        .foregroundStyle(.textSecondary)
                    Text("$\(Int(adjustedResult.cuotaMXN)) MXN/mes")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.sunOrange)
                    Text("≈ $\(String(format: "%.2f", adjustedResult.cuotaUSDC)) USDC")
                        .font(.sunCaption)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.surfaceGray)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // HCAI: 4-variable breakdown
                HCAIBreakdownView(result: adjustedResult)

                // HCAI: Natural language explanation (Foundation Models placeholder)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Explicación en lenguaje natural", systemImage: "sparkles")
                        .font(.sunCaption.weight(.semibold))
                        .foregroundStyle(.chainIndigo)
                    Text(adjustedResult.explicacion)
                        .font(.sunBody)
                        .foregroundStyle(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.chainIndigo.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // HCAI: Override — user control, always visible, never blockable
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.sunOrange)
                        Text("Ajusta tu propuesta")
                            .font(.sunHeading)
                        Spacer()
                        // HCAI badge
                        Text("Tú decides")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.sunOrange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.sunOrange.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Text("Cambia el plazo y ve cómo cambia tu cuota al instante.")
                        .font(.sunCaption)
                        .foregroundStyle(.textSecondary)

                    HStack(spacing: 0) {
                        ForEach(PaymentTerm.allCases) { term in
                            Button {
                                selectedTerm = term
                                recalculate(term: term)
                            } label: {
                                VStack(spacing: 2) {
                                    Text(term.label)
                                        .font(.sunCaption.weight(.semibold))
                                    if let cuota = cuotaForTerm(term) {
                                        Text("$\(Int(cuota))/mes")
                                            .font(.caption2)
                                            .foregroundStyle(selectedTerm == term ? .white.opacity(0.85) : .textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTerm == term ? Color.sunOrange : Color.clear)
                                .foregroundStyle(selectedTerm == term ? .white : .textPrimary)
                            }
                            .accessibilityLabel("Plazo \(term.label)\(selectedTerm == term ? ", seleccionado" : "")")
                        }
                    }
                    .background(Color.surfaceGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
                .background(Color.sunOrange.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sunOrange.opacity(0.2), lineWidth: 1))

                // Savings estimate
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ahorro estimado mensual")
                            .font(.sunCaption)
                            .foregroundStyle(.textSecondary)
                        Text("$\(Int(adjustedResult.ahorroEstimadoMXN)) MXN/mes vs. CFE")
                            .font(.sunHeading)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                }
                .padding(16)
                .background(Color.green.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // CTAs
                VStack(spacing: 12) {
                    Button {
                        showSummary = true
                    } label: {
                        Text("Publicar mi proyecto")
                            .font(.sunHeading)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.sunOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Publicar proyecto en blockchain. Requiere confirmación con Face ID.")

                    Text("Podrás revisar todos los detalles antes de confirmar con Face ID")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .navigationTitle("Tu cuota solar")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSummary) {
            ProjectSummaryView(result: adjustedResult)
        }
    }

    private func recalculate(term: PaymentTerm) {
        adjustedResult = appState.calculateQuota(
            consumoMXN: result.consumoKWh * 3.75,
            ubicacion: result.ubicacion,
            plazo: term
        )
    }

    private func cuotaForTerm(_ term: PaymentTerm) -> Double? {
        let base = result.cuotaMXN * Double(result.plazoMeses)
        let factor = 1.0 + (36.0 / Double(term.rawValue) - 1) * 0.15
        return (base / Double(term.rawValue) * factor).rounded()
    }
}
