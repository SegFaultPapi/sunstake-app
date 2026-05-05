import SwiftUI

struct ProjectDetailView: View {
    let project: SolarProject
    @State private var showPurchase = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(project.ciudad), \(project.estado)")
                                .font(.dsTitle)
                            Text("Beneficiario: \(project.beneficiario)")
                                .font(.dsCaption)
                                .foregroundStyle(.textSecondary)
                        }
                        Spacer()
                        StatusBadge(status: project.status)
                    }

                    // Funding progress
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Financiamiento")
                                .font(.dsCaption)
                                .foregroundStyle(.textSecondary)
                            Spacer()
                            Text("\(Int(project.porcentajeFinanciado * 100))% · $\(Int(project.montoTotalUSD * project.porcentajeFinanciado)) de $\(Int(project.montoTotalUSD)) USD")
                                .font(.dsCaption.weight(.semibold))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        project.porcentajeFinanciado >= 1.0
                                        ? AnyShapeStyle(Color.gray)
                                        : AnyShapeStyle(LinearGradient(colors: [.chain500, .chain500.opacity(0.7)],
                                                         startPoint: .leading, endPoint: .trailing))
                                    )
                                    .frame(width: geo.size.width * project.porcentajeFinanciado, height: 8)
                                    .animation(.easeOut(duration: 0.8), value: project.porcentajeFinanciado)
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding(20)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Returns
                VStack(spacing: 0) {
                    ReturnRow(label: "Rendimiento anual esperado", value: "\(String(format: "%.1f", project.rendimientoAnualPct))%", accent: true)
                    Divider().padding(.horizontal)
                    ReturnRow(label: "Plazo restante", value: "\(project.mesesRestantes) meses")
                    Divider().padding(.horizontal)
                    ReturnRow(label: "Plazo total", value: "\(project.plazoTotalMeses) meses")
                    Divider().padding(.horizontal)
                    ReturnRow(label: "Inversión mínima", value: "$\(Int(project.montoMinUSD)) USD")
                }
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Environmental impact — HCAI: tangible impact for Carlos
                VStack(alignment: .leading, spacing: 12) {
                    Label("Impacto ambiental medible", systemImage: "leaf.fill")
                        .font(.dsHeading)
                        .foregroundStyle(.success)
                    HStack(spacing: 0) {
                        ImpactStat(
                            icon: "wind",
                            value: "\(String(format: "%.1f", project.co2ToneladasAnio))",
                            unit: "ton CO₂",
                            label: "evitadas/año"
                        )
                        Divider().frame(height: 50)
                        ImpactStat(
                            icon: "bolt.fill",
                            value: String(format: "%.1fk", project.kwhGeneradosAnio / 1000),
                            unit: "kWh",
                            label: "generados/año"
                        )
                        Divider().frame(height: 50)
                        ImpactStat(
                            icon: "house.fill",
                            value: "87",
                            unit: "%",
                            label: "cobertura CFE"
                        )
                    }
                }
                .padding(16)
                .background(Color.success.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Contract — HCAI: verifiable trust
                ContractInfoView(
                    address: project.contractAddress,
                    network: "Base Sepolia",
                    explorerURL: "https://sepolia.basescan.org"
                )

                // Estimator — interactive
                if project.isOpen {
                    InvestmentEstimatorView(project: project)
                }

                // CTA
                if project.isOpen {
                    Button {
                        showPurchase = true
                    } label: {
                        Text("Invertir en este proyecto")
                            .font(.dsHeading)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.chain500)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Invertir en proyecto de \(project.ciudad). Mínimo $\(Int(project.montoMinUSD)) USD.")
                } else {
                    Label("Este proyecto está cerrado", systemImage: "lock.fill")
                        .font(.dsHeading)
                        .foregroundStyle(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(24)
        }
        .navigationTitle("\(project.ciudad)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPurchase) {
            PurchaseFlowView(project: project)
        }
    }
}

struct ReturnRow: View {
    let label: String
    let value: String
    var accent: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.dsSubhead)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(accent ? .dsTitle : .dsSubhead.weight(.semibold))
                .foregroundStyle(accent ? .chain500 : .textPrimary)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm + 4)
    }
}

struct ImpactStat: View {
    let icon: String
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.success)
            Text(value)
                .font(.system(.body, design: .rounded, weight: .bold))
            Text(unit)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.success)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InvestmentEstimatorView: View {
    let project: SolarProject
    @State private var amount: Double = 50

    var monthlyYield: Double { amount * project.rendimientoMensualPct }
    var annualYield: Double { amount * project.rendimientoAnualPct / 100 }
    var tokens: Int { Int(amount) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estima tu rendimiento")
                .font(.dsHeading)

            Slider(value: $amount, in: 1...500, step: 1)
                .tint(.chain500)
                .accessibilityLabel("Monto de inversión: \(Int(amount)) dólares")

            HStack {
                Text("Monto: $\(Int(amount)) USD")
                    .font(.dsCaption.weight(.semibold))
                Spacer()
                Text("\(tokens) fracciones")
                    .font(.dsCaption)
                    .foregroundStyle(.textSecondary)
            }

            HStack(spacing: 0) {
                EstimateChip(label: "Mensual", value: "$\(String(format: "%.2f", monthlyYield)) USD")
                Divider().frame(height: 30)
                EstimateChip(label: "Anual", value: "$\(String(format: "%.2f", annualYield)) USD")
                Divider().frame(height: 30)
                EstimateChip(label: "Tasa", value: "\(String(format: "%.1f", project.rendimientoAnualPct))%")
            }
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Estimación basada en historial de pagos. No garantizada.")
                .font(.caption2)
                .foregroundStyle(.textSecondary)
        }
        .padding(16)
        .background(Color.chain500.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct EstimateChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.dsCaption.weight(.bold))
                .foregroundStyle(.chain500)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

struct StatusBadge: View {
    let status: ProjectStatus

    var body: some View {
        switch status {
        case .open:
            Label("Abierto", systemImage: "circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.success)
        case .funded:
            Label("Cerrado", systemImage: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.textSecondary)
        case .completed:
            Label("Completado", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.chain500)
        }
    }
}
