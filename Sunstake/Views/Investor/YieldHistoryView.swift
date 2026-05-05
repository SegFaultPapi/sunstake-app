import SwiftUI

struct YieldHistoryView: View {
    @Environment(AppState.self) var appState

    private var totalUSDC: Double {
        appState.yieldHistory.reduce(0) { $0 + $1.montoUSDC }
    }
    private var totalMXN: Double {
        appState.yieldHistory.reduce(0) { $0 + $1.montoMXN }
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
                            Text("$\(String(format: "%.2f", totalUSDC)) USDC")
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
                                label: "Tasa real",
                                value: "~9.1% anual"
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Active investments
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mis inversiones activas")
                            .font(.dsHeading)

                        ForEach(appState.investedProjects) { project in
                            HStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(project.ciudad), \(project.estado)")
                                        .font(.dsCaption.weight(.semibold))
                                    Text("\(project.mesesRestantes) m · \(String(format: "%.1f", project.rendimientoAnualPct))% anual")
                                        .font(.dsCaption2)
                                        .foregroundStyle(.textSecondary)
                                }
                                Spacer()
                                Text("$\(String(format: "%.2f", 50 * project.rendimientoMensualPct))/mes")
                                    .font(.dsCaption.weight(.bold))
                                    .foregroundStyle(.chain500)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel(
                                "\(project.ciudad), \(project.estado). " +
                                "\(project.mesesRestantes) meses restantes. " +
                                "Rendimiento estimado $\(String(format: "%.2f", 50 * project.rendimientoMensualPct)) USD al mes."
                            )
                        }
                    }

                    // History list
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Historial de rendimientos")
                                .font(.dsHeading)
                            Spacer()
                            Button {
                                exportCSV()
                            } label: {
                                Label("Exportar", systemImage: "square.and.arrow.up")
                                    .font(.dsCaption)
                                    .foregroundStyle(.chain500)
                            }
                            .accessibilityLabel("Exportar historial como CSV para declaración fiscal")
                        }

                        ForEach(appState.yieldHistory) { entry in
                            YieldEntryRow(entry: entry)
                        }
                    }

                    // HCAI: transparency notice
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.chain500)
                        Text("Cada rendimiento está verificado en blockchain. Toca el código de verificación para confirmarlo tú mismo en Basescan.")
                            .font(.caption2)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding(12)
                    .background(Color.chain500.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(24)
            }
            .navigationTitle("Mis rendimientos")
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
                    Text("+$\(String(format: "%.2f", entry.montoUSDC)) USDC")
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
                    Text("\(entry.txHashCorto) · Basescan ↗")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.chain500.opacity(0.75))
                }
                .accessibilityLabel("Ver transacción \(entry.txHashCorto) en Basescan")
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
