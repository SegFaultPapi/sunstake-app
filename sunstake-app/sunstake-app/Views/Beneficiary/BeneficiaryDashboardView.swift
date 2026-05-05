import SwiftUI

struct BeneficiaryDashboardView: View {
    @Environment(AppState.self) var appState
    @State private var showPaymentConfirm = false
    @State private var showPaymentLoader = false

    private var project: SolarProject { SolarProject.mockProjects[0] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Ownership ring
                    VStack(spacing: 16) {
                        OwnershipRingView(
                            percentage: appState.ownershipPct,
                            mesesPagados: project.mesesPagados,
                            plazoTotal: project.plazoTotalMeses
                        )

                        // Key stats row
                        HStack(spacing: 0) {
                            StatChip(
                                icon: "calendar",
                                label: "Pagados",
                                value: "\(project.mesesPagados)/\(project.plazoTotalMeses) meses"
                            )
                            Divider().frame(height: 32)
                            StatChip(
                                icon: "arrow.down.circle",
                                label: "Ahorro acumulado",
                                value: "$\(Int(Double(project.mesesPagados) * (appState.quotaResult?.ahorroEstimadoMXN ?? 380))) MXN"
                            )
                        }
                        .background(Color.surfaceGray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Next payment card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Próximo pago")
                                    .font(.sunCaption)
                                    .foregroundStyle(.textSecondary)
                                Text("15 de junio · $\(Int(appState.quotaResult?.cuotaMXN ?? 850)) MXN")
                                    .font(.sunHeading)
                            }
                            Spacer()
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.sunOrange)
                        }

                        Button {
                            showPaymentConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "faceid")
                                Text("Pagar cuota de junio")
                                    .font(.sunHeading)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.sunOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityLabel("Pagar cuota mensual de junio. Requiere Face ID.")
                    }
                    .padding(16)
                    .background(Color.surfaceGray)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Panel info
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tu panel solar", systemImage: "sun.max.fill")
                            .font(.sunHeading)
                            .foregroundStyle(.sunOrange)

                        HStack(spacing: 16) {
                            PanelStat(icon: "location.fill", label: "Ubicación", value: "Guadalajara, JAL")
                            PanelStat(icon: "bolt.fill", label: "Capacidad", value: "2 kW")
                            PanelStat(icon: "leaf.fill", label: "CO₂ evitado", value: "1.2 ton/año")
                        }
                    }
                    .padding(16)
                    .background(Color.sunYellow.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Contract transparency — HCAI verifiable trust
                    ContractInfoView(
                        address: "0x7f3a4b2c9d1e8f5a0c3b6d9e2f1a4b7c0d3e6f9a",
                        network: "Base Sepolia",
                        explorerURL: "https://sepolia.basescan.org"
                    )

                    // Payment history
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Historial de pagos")
                            .font(.sunHeading)
                        ForEach(appState.paymentHistory) { payment in
                            PaymentRow(payment: payment)
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Mi panel solar")
            .refreshable {
                // In real app: refresh on-chain data
            }
            .sheet(isPresented: $showPaymentConfirm) {
                BiometricConfirmationSheet(
                    title: "Pagar cuota de junio",
                    subtitle: "$\(Int(appState.quotaResult?.cuotaMXN ?? 850)) MXN · $\(String(format: "%.2f", appState.quotaResult?.cuotaUSDC ?? 48.57)) USDC + gas fee ~$0.01 USD"
                ) {
                    showPaymentConfirm = false
                    showPaymentLoader = true
                    Task {
                        await appState.payMonthlyQuota()
                    }
                }
            }
            .navigationDestination(isPresented: $showPaymentLoader) {
                TransactionLoaderView(
                    successTitle: "¡Pago confirmado!",
                    successSubtitle: "Tu pago quedó registrado en blockchain. Tu porcentaje de propiedad aumentó.",
                    destination: { BeneficiaryDashboardView() }
                )
            }
        }
    }
}

struct StatChip: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.sunOrange)
            Text(value)
                .font(.sunCaption.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct PanelStat: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.sunOrange)
                .font(.caption)
            Text(value)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PaymentRow: View {
    let payment: Payment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.fecha, style: .date)
                    .font(.sunCaption.weight(.medium))
                Text("$\(String(format: "%.2f", payment.montoUSDC)) USDC")
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            Text("$\(Int(payment.montoMXN)) MXN")
                .font(.sunCaption.weight(.semibold))

            Button {
                if let url = URL(string: "https://sepolia.basescan.org/tx/\(payment.txHash)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 3) {
                    Text(payment.txHashCorto)
                        .font(.caption2.monospaced())
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption2)
                }
                .foregroundStyle(.chainIndigo)
            }
            .accessibilityLabel("Ver transacción \(payment.txHashCorto) en Basescan")
        }
        .padding(.vertical, 4)
        Divider()
    }
}
