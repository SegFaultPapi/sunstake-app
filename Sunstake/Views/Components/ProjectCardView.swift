import SwiftUI

/// Card compacta para el explorador de proyectos.
/// Muestra solo la información esencial; el detalle completo
/// (CO₂, plazo, contrato, estimador) está en ProjectDetailView.
struct ProjectCardView: View {
    let project: SolarProject

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: location + progress
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "house.fill")
                        .font(.dsCaption2)
                        .foregroundStyle(.secondary500)
                    Text("\(project.ciudad), \(project.estado)")
                        .font(.dsSubhead.weight(.semibold))
                        .foregroundStyle(.textPrimary)
                }

                // Barra de financiamiento
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                project.status == .funded
                                    ? AnyShapeStyle(Color.gray)
                                    : AnyShapeStyle(
                                        LinearGradient(
                                            colors: [.chain500, .chain500.opacity(0.55)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .frame(
                                width: geo.size.width * project.porcentajeFinanciado,
                                height: 4
                            )
                    }
                }
                .frame(height: 4)

                Text("\(Int(project.porcentajeFinanciado * 100))% financiado")
                    .font(.dsCaption2)
                    .foregroundStyle(.textSecondary)
            }

            Spacer(minLength: 8)

            // Right: yield + min + status + chevron
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: project.status)

                Text("\(String(format: "%.1f", project.rendimientoAnualPct))% anual")
                    .font(.dsCaption.weight(.bold))
                    .foregroundStyle(.chain500)

                Text("desde $\(Int(project.montoMinUSD)) USD")
                    .font(.dsCaption2)
                    .foregroundStyle(.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.dsCaption2.weight(.semibold))
                .foregroundStyle(Color.gray.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.chain500.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.chain500, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(project.ciudad), \(project.estado). " +
            "\(String(format: "%.1f", project.rendimientoAnualPct))% anual. " +
            "\(Int(project.porcentajeFinanciado * 100))% financiado. " +
            "Inversión mínima $\(Int(project.montoMinUSD)) USD. Toca para ver detalles."
        )
    }
}
