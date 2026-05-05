import SwiftUI

struct ProjectSummaryView: View {
    @Environment(AppState.self) var appState
    let result: QuotaResult
    @State private var showLoader = false
    @State private var showBiometric = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Revisa tu proyecto")
                        .font(.sunTitle)
                    Text("Este es el contrato que se registrará en blockchain. Revísalo antes de confirmar con Face ID.")
                        .font(.sunCaption)
                        .foregroundStyle(.textSecondary)
                }

                // Summary card
                VStack(spacing: 0) {
                    SummaryRow(label: "Tu cuota mensual", value: "$\(Int(result.cuotaMXN)) MXN/mes", accent: true)
                    Divider().padding(.horizontal)
                    SummaryRow(label: "Plazo total", value: "\(result.plazoMeses) meses")
                    Divider().padding(.horizontal)
                    SummaryRow(label: "Monto total a financiar", value: "$\(Int(result.montoTotalMXN)) MXN")
                    Divider().padding(.horizontal)
                    SummaryRow(label: "Panel solar", value: result.tamanoPanel)
                    Divider().padding(.horizontal)
                    SummaryRow(label: "Cobertura CFE", value: "\(Int(result.coberturaPct))%")
                    Divider().padding(.horizontal)
                    SummaryRow(label: "Rendimiento para inversores", value: "\(String(format: "%.1f", result.rendimientoInversorPct))% anual")
                    Divider().padding(.horizontal)
                    SummaryRow(label: "Comisión Sunstake", value: "7% sobre rendimientos")
                }
                .background(Color.surfaceGray)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Blockchain info
                VStack(alignment: .leading, spacing: 12) {
                    Label("Contrato en blockchain", systemImage: "link.circle.fill")
                        .font(.sunHeading)
                        .foregroundStyle(.chainIndigo)
                    VStack(spacing: 8) {
                        BlockchainInfoRow(label: "Red", value: "Base Sepolia (modo de prueba)")
                        BlockchainInfoRow(label: "Estándar de token", value: "ERC-1155 fraccionado")
                        BlockchainInfoRow(label: "Moneda", value: "USDC (dólares digitales estables)")
                    }
                    Text("Al publicar, el contrato quedará registrado públicamente y los inversores podrán financiarlo.")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
                .padding(16)
                .background(Color.chainIndigo.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // HCAI: Responsible design notice
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.chainIndigo)
                    Text("Se requerirá tu Face ID para confirmar. No se realizarán transacciones automáticas sin tu aprobación.")
                        .font(.sunCaption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(14)
                .background(Color.chainIndigo.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // CTA
                Button {
                    showBiometric = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.title3)
                        Text("Confirmar con Face ID")
                            .font(.sunHeading)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.sunOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Confirmar publicación del proyecto con Face ID")
            }
            .padding(24)
        }
        .navigationTitle("Resumen del proyecto")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBiometric) {
            BiometricConfirmationSheet(
                title: "Publicar proyecto",
                subtitle: "Cuota $\(Int(result.cuotaMXN)) MXN/mes · \(result.plazoMeses) meses · Base Sepolia"
            ) {
                showBiometric = false
                showLoader = true
                Task {
                    await appState.publishProject()
                }
            }
        }
        .navigationDestination(isPresented: $showLoader) {
            TransactionLoaderView(
                successTitle: "¡Proyecto publicado!",
                successSubtitle: "Tu proyecto ya está en blockchain. Los inversores pueden comenzar a financiarlo.",
                destination: { BeneficiaryDashboardView() }
            )
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    var accent: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.sunCaption)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(accent ? .sunHeading : .sunCaption.weight(.semibold))
                .foregroundStyle(accent ? .sunOrange : .textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct BlockchainInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.sunCaption)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.sunCaption.weight(.medium))
                .foregroundStyle(.textPrimary)
        }
    }
}
