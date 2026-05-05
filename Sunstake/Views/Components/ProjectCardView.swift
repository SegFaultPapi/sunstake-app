import SwiftUI

struct ProjectCardView: View {
    let project: SolarProject

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "house.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary500)
                        Text("\(project.ciudad), \(project.estado)")
                            .font(.dsHeading)
                    }
                    Text("Beneficiario: \(project.beneficiario)")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                StatusBadge(status: project.status)
            }

            // Funding progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                project.status == .funded
                                ? AnyShapeStyle(Color.gray)
                                : AnyShapeStyle(LinearGradient(colors: [.chain500, .chain500.opacity(0.6)],
                                                 startPoint: .leading, endPoint: .trailing))
                            )
                            .frame(width: geo.size.width * project.porcentajeFinanciado, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(Int(project.porcentajeFinanciado * 100))% financiado")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                    Text("$\(Int(project.montoTotalUSD)) USD total")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
            }

            // Metrics row
            HStack(spacing: 0) {
                CardMetric(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .chain500,
                    value: "\(String(format: "%.1f", project.rendimientoAnualPct))%",
                    label: "anual"
                )
                Divider().frame(height: 28)
                CardMetric(
                    icon: "calendar",
                    iconColor: .secondary500,
                    value: "\(project.mesesRestantes) m",
                    label: "restantes"
                )
                Divider().frame(height: 28)
                CardMetric(
                    icon: "leaf.fill",
                    iconColor: .success,
                    value: "\(String(format: "%.1f", project.co2ToneladasAnio)) ton",
                    label: "CO₂/año"
                )
                Divider().frame(height: 28)
                CardMetric(
                    icon: "dollarsign.circle.fill",
                    iconColor: .chain500,
                    value: "desde $\(Int(project.montoMinUSD))",
                    label: "USD"
                )
            }
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(project.ciudad), \(project.estado). " +
            "\(String(format: "%.1f", project.rendimientoAnualPct))% anual. " +
            "\(Int(project.porcentajeFinanciado * 100))% financiado. " +
            "\(String(format: "%.1f", project.co2ToneladasAnio)) toneladas de CO₂ evitadas al año."
        )
    }
}

struct CardMetric: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.textPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
