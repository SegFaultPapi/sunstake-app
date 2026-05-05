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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mis inversiones activas")
                            .font(.dsHeading)

                        ForEach(appState.investedProjects) { project in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(project.ciudad), \(project.estado)")
                                        .font(.dsCaption.weight(.semibold))
                                    Text("\(project.mesesRestantes) meses restantes · \(String(format: "%.1f", project.rendimientoAnualPct))% anual")
                                        .font(.caption2)
                                        .foregroundStyle(.textSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("$\(String(format: "%.2f", 50 * project.rendimientoMensualPct)) USD/mes")
                                        .font(.dsCaption.weight(.bold))
                                        .foregroundStyle(.chain500)
                                    Text("rendimiento est.")
                                        .font(.caption2)
                                        .foregroundStyle(.textSecondary)
                                }
                            }
                            .padding(14)
                            .background(Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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

struct YieldEntryRow: View {
    let entry: YieldEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.proyecto)
                        .font(.dsCaption.weight(.medium))
                    Text(entry.fecha, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+$\(String(format: "%.2f", entry.montoUSDC)) USDC")
                        .font(.dsCaption.weight(.bold))
                        .foregroundStyle(.success)
                    Text("≈ $\(Int(entry.montoMXN)) MXN")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
            }
            HStack {
                Image(systemName: "link.circle")
                    .font(.caption2)
                    .foregroundStyle(.chain500)
                Button {
                    if let url = URL(string: "https://sepolia.basescan.org/tx/\(entry.txHash)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(entry.txHashCorto)
                            .font(.caption2.monospaced())
                        Text("· Ver en Basescan")
                            .font(.caption2)
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.chain500)
                }
                .accessibilityLabel("Ver transacción \(entry.txHashCorto) en Basescan")
                Spacer()
            }
        }
        .padding(.vertical, 8)
        Divider()
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
