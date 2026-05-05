import SwiftUI

struct YieldHistoryView: View {
    @Environment(AppState.self) var appState

    private var totalUSDC: Double {
        appState.yieldHistory.reduce(0) { $0 + $1.montoUSDC }
    }
    private var totalMXN: Double {
        appState.yieldHistory.reduce(0) { $0 + $1.montoMXN }
    }

    private var hasNoActivity: Bool {
        appState.investedProjects.isEmpty && appState.yieldHistory.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Summary header
                    VStack(spacing: 16) {
                        VStack(spacing: 6) {
                            Text("Rendimiento total acumulado")
                                .font(.dsSubhead)
                                .foregroundStyle(.textSecondary)
                            Text("$\(String(format: "%.2f", totalUSDC)) USD")
                                .font(.dsDisplay)
                                .foregroundStyle(.chain500)
                            Text("≈ $\(Int(totalMXN)) MXN")
                                .font(.dsFootnote)
                                .foregroundStyle(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)

                        HStack(spacing: 0) {
                            YieldSummaryChip(
                                label: "Este mes",
                                value: "$\(String(format: "%.2f", monthlyTotal)) USDC"
                            )
                            Divider().frame(height: 30)
                            YieldSummaryChip(
                                label: "Proyectos activos",
                                value: "\(appState.investedProjects.count)"
                            )
                            Divider().frame(height: 30)
                            YieldSummaryChip(
                                label: "Total invertido",
                                value: "$\(String(format: "%.2f", appState.totalInvestedUSDC)) USD"
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if appState.isRestoringInvestorState {
                        RestoringInvestorStateView()
                    } else if appState.investorRestoreFailed && hasNoActivity {
                        RestoreFailedView {
                            Task { await appState.restoreInvestorStateFromChain() }
                        }
                    } else if hasNoActivity {
                        EmptyYieldStateView()
                    } else {
                        // Active investments
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mis inversiones activas")
                                .font(.dsHeading)

                            if appState.investedProjects.isEmpty {
                                EmptyInvestmentsRow()
                            } else {
                                ForEach(appState.investedProjects) { project in
                                    let invertido = appState.investedAmount(in: project.id)
                                    HStack(spacing: 0) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(project.ciudad), \(project.estado)")
                                                .font(.dsCaption.weight(.semibold))
                                            Text("\(project.mesesRestantes) m · \(String(format: "%.1f", project.rendimientoAnualPct))% anual · invertiste $\(String(format: "%.2f", invertido)) USD")
                                                .font(.dsCaption2)
                                                .foregroundStyle(.textSecondary)
                                        }
                                        Spacer()
                                        Text("$\(String(format: "%.2f", invertido * project.rendimientoMensualPct))/mes")
                                            .font(.dsCaption.weight(.bold))
                                            .foregroundStyle(.chain500)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .accessibilityLabel(
                                        "\(project.ciudad), \(project.estado). " +
                                        "Invertiste \(Int(invertido)) dolares. " +
                                        "\(project.mesesRestantes) meses restantes. " +
                                        "Rendimiento estimado $\(String(format: "%.2f", invertido * project.rendimientoMensualPct)) USD al mes."
                                    )
                                }
                            }
                        }

                        // History list
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Historial de rendimientos")
                                    .font(.dsHeading)
                                Spacer()
                                if !appState.yieldHistory.isEmpty {
                                    Button {
                                        exportCSV()
                                    } label: {
                                        Label("Exportar", systemImage: "square.and.arrow.up")
                                            .font(.dsCaption)
                                            .foregroundStyle(.chain500)
                                    }
                                    .accessibilityLabel("Exportar historial como CSV para declaración fiscal")
                                }
                            }

                            if appState.yieldHistory.isEmpty {
                                EmptyYieldHistoryRow()
                            } else {
                                ForEach(appState.yieldHistory) { entry in
                                    YieldEntryRow(entry: entry)
                                }
                            }
                        }

                        // HCAI: transparency notice
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.chain500)
                            Text("Cada rendimiento está verificado en la red de pagos. Toca el código de verificación para confirmarlo tú mismo en los detalles de la transacción.")
                                .font(.caption2)
                                .foregroundStyle(.textSecondary)
                        }
                        .padding(12)
                        .background(Color.chain500.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(24)
            }
            .changeRoleButton()
            .navigationTitle("Mis rendimientos")
            .task {
                if appState.investedProjects.isEmpty && !appState.isRestoringInvestorState {
                    await appState.restoreInvestorStateFromChain()
                }
            }
        }
    }

    private var monthlyTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        return appState.yieldHistory
            .filter { calendar.isDate($0.fecha, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.montoUSDC }
    }

    private func exportCSV() {
        // In real app: generate CSV and share
    }
}

private struct EmptyYieldStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.chain500)
            Text("Aún no tienes inversiones")
                .font(.dsHeading)
            Text("Cuando inviertas en un proyecto solar, verás aquí tus rendimientos verificables en blockchain.")
                .font(.dsCaption)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct EmptyInvestmentsRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.circle")
                .foregroundStyle(.chain500)
            Text("Explora proyectos en la pestaña Proyectos para hacer tu primera inversión.")
                .font(.dsCaption)
                .foregroundStyle(.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct EmptyYieldHistoryRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock")
                .foregroundStyle(.textSecondary)
            Text("Los rendimientos aparecerán aquí cuando los beneficiarios paguen sus cuotas mensuales.")
                .font(.dsCaption)
                .foregroundStyle(.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RestoreFailedView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.warning)
            Text("No pudimos conectar a la red de pagos")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(.textPrimary)
            Text("Verifica tu conexión e intenta de nuevo.")
                .font(.dsCaption2)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                Label("Reintentar", systemImage: "arrow.clockwise")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.chain500)
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Reintentar cargar inversiones desde la red de pagos")
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct RestoringInvestorStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(.chain500)
            Text("Verificando tus inversiones en la red de pagos…")
                .font(.dsCaption)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Fila compacta de historial de rendimientos.
/// Muestra proyecto + fecha + monto en una sola línea;
/// el código de verificación queda en una línea secundaria pequeña.
struct YieldEntryRow: View {
    let entry: YieldEntry

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.proyecto)
                        .font(.dsCaption.weight(.medium))
                        .foregroundStyle(.textPrimary)
                    Text(entry.fecha, style: .date)
                        .font(.dsCaption2)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("+$\(String(format: "%.2f", entry.montoUSDC)) USD")
                        .font(.dsCaption.weight(.bold))
                        .foregroundStyle(.success)
                    Text("≈ $\(Int(entry.montoMXN)) MXN")
                        .font(.dsCaption2)
                        .foregroundStyle(.textSecondary)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 5)

            // Línea de verificación — siempre visible, tamaño mínimo
            HStack(spacing: 3) {
                Image(systemName: "link")
                    .font(.system(size: 9))
                    .foregroundStyle(.chain500.opacity(0.7))
                Button {
                    if let url = URL(string: "https://sepolia.basescan.org/tx/\(entry.txHash)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("\(entry.txHashCorto) · Ver detalles ↗")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.chain500.opacity(0.75))
                }
                .accessibilityLabel("Ver detalles de la transacción \(entry.txHashCorto)")
                Spacer()
            }
            .padding(.bottom, 10)

            Divider()
        }
    }
}

struct YieldSummaryChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            Text(value)
                .font(.dsFootnote.weight(.bold))
                .foregroundStyle(.chain500)
            Text(label)
                .font(.dsCaption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
