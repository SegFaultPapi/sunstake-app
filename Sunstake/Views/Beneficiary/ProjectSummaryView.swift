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
                        .font(.dsTitle)
                    Text("Este es el registro que se guardará en la red de pagos verificable. Revísalo antes de confirmar con Face ID.")
                        .font(.dsCaption)
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
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Blockchain info
                VStack(alignment: .leading, spacing: 12) {
                    Label("Registro del proyecto", systemImage: "link.circle.fill")
                        .font(.dsHeading)
                        .foregroundStyle(.chain500)
                    VStack(spacing: 8) {
                        BlockchainInfoRow(label: "Red", value: "Base Sepolia (modo de prueba)")
                        BlockchainInfoRow(label: "Tipo de participación", value: "Fraccionada")
                        BlockchainInfoRow(label: "Moneda", value: "USD (dólares digitales)")
                    }
                    Text("Al publicar, el contrato quedará registrado públicamente y los inversores podrán financiarlo.")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
                .padding(16)
                .background(Color.chain500.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // HCAI: Responsible design notice
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.chain500)
                    Text("Se requerirá tu Face ID para confirmar. No se realizarán transacciones automáticas sin tu aprobación.")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(14)
                .background(Color.chain500.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // CTA
                Button {
                    showBiometric = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.title3)
                        Text("Confirmar con Face ID")
                            .font(.dsHeading)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.secondary500)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Confirmar publicación del proyecto con Face ID")
            }
            .padding(24)
        }
        .changeRoleButton()
        .navigationTitle("Resumen del proyecto")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBiometric) {
            BiometricConfirmationSheet(
                title: "Publicar proyecto",
                subtitle: "Cuota $\(Int(result.cuotaMXN)) MXN/mes · \(result.plazoMeses) meses · Modo de prueba"
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
                .font(.dsCaption)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(accent ? .dsHeading : .dsCaption.weight(.semibold))
                .foregroundStyle(accent ? .secondary500 : .textPrimary)
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
                .font(.dsCaption)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.dsCaption.weight(.medium))
                .foregroundStyle(.textPrimary)
        }
    }
}
