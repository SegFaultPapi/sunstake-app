import SwiftUI

struct BeneficiaryDashboardView: View {
    @Environment(AppState.self) var appState
    @State private var showPaymentConfirm = false
    @State private var showPaymentLoader = false

    private var project: SolarProject? { appState.activeProject }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Ownership ring
                    VStack(spacing: 16) {
                        OwnershipRingView(
                            percentage: appState.ownershipPct,
                            mesesPagados: project?.mesesPagados ?? appState.paymentHistory.count,
                            plazoTotal: project?.plazoTotalMeses ?? (appState.quotaResult?.plazoMeses ?? 36)
                        )

                        // Key stats row
                        HStack(spacing: 0) {
                            StatChip(
                                icon: "calendar",
                                label: "Pagados",
                                value: "\(project?.mesesPagados ?? appState.paymentHistory.count)/\(project?.plazoTotalMeses ?? (appState.quotaResult?.plazoMeses ?? 36)) meses"
                            )
                            Divider().frame(height: 32)
                            StatChip(
                                icon: "arrow.down.circle",
                                label: "Ahorro acumulado",
                                value: "$\(Int(Double(project?.mesesPagados ?? appState.paymentHistory.count) * (appState.quotaResult?.ahorroEstimadoMXN ?? 0))) MXN"
                            )
                        }
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Next payment card
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                                Text("Próximo pago")
                                    .font(.dsSubhead)
                                    .foregroundStyle(.textSecondary)
                                Text("15 de junio · $\(Int(appState.quotaResult?.cuotaMXN ?? 850)) MXN")
                                    .font(.dsHeading)
                            }
                            Spacer()
                            Image(systemName: "clock.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary500)
                        }

                        Button {
                            showPaymentConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "faceid")
                                Text("Pagar cuota de junio")
                                    .font(.dsHeading)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.secondary500)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityLabel("Pagar cuota mensual de junio. Requiere Face ID.")
                    }
                    .padding(16)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Panel info
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tu panel solar", systemImage: "sun.max.fill")
                            .font(.dsHeading)
                            .foregroundStyle(.secondary500)

                        HStack(spacing: 16) {
                            PanelStat(
                                icon: "location.fill",
                                label: "Ubicación",
                                value: project.map { "\($0.ciudad), \($0.estado)" } ?? (appState.quotaResult?.ubicacion ?? "—")
                            )
                            PanelStat(
                                icon: "bolt.fill",
                                label: "Capacidad",
                                value: appState.quotaResult?.tamanoPanel ?? "—"
                            )
                            PanelStat(
                                icon: "leaf.fill",
                                label: "CO₂ evitado",
                                value: project.map { "\(String(format: "%.1f", $0.co2ToneladasAnio)) ton/año" } ?? "—"
                            )
                        }
                    }
                    .padding(16)
                    .background(Color.primary500.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Contract transparency — HCAI verifiable trust
                    if let project {
                        ContractInfoView(
                            address: project.contractAddress,
                            network: appState.networkConfig.networkLabel,
                            explorerURL: appState.networkConfig.baseScanBaseURL.absoluteString
                        )
                    }

                    // Payment history
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Historial de pagos")
                            .font(.dsHeading)
                        if appState.paymentHistory.isEmpty {
                            EmptyPaymentHistoryRow()
                        } else {
                            ForEach(appState.paymentHistory) { payment in
                                PaymentRow(payment: payment)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .changeRoleButton()
            .navigationTitle("Mi panel solar")
            .refreshable {
                // In real app: refresh on-chain data
            }
            .sheet(isPresented: $showPaymentConfirm) {
                BiometricConfirmationSheet(
                    title: "Pagar cuota de junio",
                    subtitle: "$\(Int(appState.quotaResult?.cuotaMXN ?? 850)) MXN · $\(String(format: "%.2f", appState.quotaResult?.cuotaUSDC ?? 48.57)) USD + costo de procesamiento ~$0.01 USD"
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
                    successSubtitle: "Tu pago quedó registrado en la red de pagos. Tu porcentaje de propiedad aumentó.",
                    destination: { BeneficiaryDashboardView() }
                )
            }
        }
    }
}

private struct EmptyPaymentHistoryRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock")
                .foregroundStyle(.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Aún no hay pagos registrados")
                    .font(.dsCaption.weight(.semibold))
                Text("Cuando hagas tu primer pago en blockchain, aparecerá aquí con su código de verificación.")
                    .font(.dsCaption2)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .foregroundStyle(.secondary500)
            Text(value)
                .font(.dsCaption.weight(.semibold))
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
                .foregroundStyle(.secondary500)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(payment.fecha, style: .date)
                        .font(.dsCaption.weight(.medium))
                    Text("$\(String(format: "%.2f", payment.montoUSDC)) USD")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Text("$\(Int(payment.montoMXN)) MXN")
                        .font(.dsCaption.weight(.semibold))
                    Button {
                        if let url = URL(string: "https://sepolia.basescan.org/tx/\(payment.txHash)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.chain500)
                    }
                    .accessibilityLabel("Ver detalles de la transacción")
                }
            }
            CopyableHashView(label: "Código de verificación", hash: payment.txHash)
        }
        .padding(.vertical, 4)
        Divider()
    }
}
