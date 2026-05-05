import SwiftUI

// HCAI: 4-variable breakdown — makes AI decision fully transparent
struct HCAIBreakdownView: View {
    let result: QuotaResult

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Label("Por qué esta cuota", systemImage: "magnifyingglass")
                    .font(.dsHeading)
                Spacer()
                Text("4 variables")
                    .font(.dsCaption2.weight(.semibold))
                    .foregroundStyle(.textSecondary)
                    .padding(.horizontal, DSSpacing.sm)
                    .padding(.vertical, 3)
                    .background(Color.surface)
                    .clipShape(Capsule())
            }

            VStack(spacing: 8) {
                BreakdownRow(
                    number: "1",
                    icon: "bolt.fill",
                    iconColor: .yellow,
                    label: "Tu consumo mensual",
                    value: "\(Int(result.consumoKWh)) kWh/mes",
                    source: "Ingresado por ti"
                )
                BreakdownRow(
                    number: "2",
                    icon: "sun.max.fill",
                    iconColor: .secondary500,
                    label: "Sol en tu zona",
                    value: "\(String(format: "%.1f", result.horasSol))h de sol/día",
                    source: "Fuente: NASA POWER API"
                )
                BreakdownRow(
                    number: "3",
                    icon: "square.fill",
                    iconColor: .chain500,
                    label: "Tamaño del panel",
                    value: result.tamanoPanel,
                    source: "Catálogo de instaladores"
                )
                BreakdownRow(
                    number: "4",
                    icon: "calendar",
                    iconColor: .success,
                    label: "Plazo elegido",
                    value: "\(result.plazoMeses) meses",
                    source: "Seleccionado por ti"
                )
            }

            // Coverage result
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cobertura de tu consumo CFE")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                    Text("\(Int(result.coberturaPct))% de tu factura")
                        .font(.dsHeading)
                        .foregroundStyle(.success)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 6)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: result.coberturaPct / 100)
                        .stroke(Color.success, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 48, height: 48)
                    Text("\(Int(result.coberturaPct))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
            .padding(12)
            .background(Color.success.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct BreakdownRow: View {
    let number: String
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let source: String

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.dsFootnote.weight(.medium))
                    .foregroundStyle(.textPrimary)
                Text(source)
                    .font(.dsCaption2)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            Text(value)
                .font(.dsFootnote.weight(.bold))
                .foregroundStyle(.textPrimary)
        }
        .padding(DSSpacing.sm + 2)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value). \(source)")
    }
}
