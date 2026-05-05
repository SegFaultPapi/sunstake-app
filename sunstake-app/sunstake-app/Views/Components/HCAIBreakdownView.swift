import SwiftUI

// HCAI: 4-variable breakdown — makes AI decision fully transparent
struct HCAIBreakdownView: View {
    let result: QuotaResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Por qué esta cuota", systemImage: "magnifyingglass")
                    .font(.sunHeading)
                Spacer()
                Text("4 variables")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.surfaceGray)
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
                    iconColor: .sunOrange,
                    label: "Sol en tu zona",
                    value: "\(String(format: "%.1f", result.horasSol))h de sol/día",
                    source: "Fuente: NASA POWER API"
                )
                BreakdownRow(
                    number: "3",
                    icon: "square.fill",
                    iconColor: .chainIndigo,
                    label: "Tamaño del panel",
                    value: result.tamanoPanel,
                    source: "Catálogo de instaladores"
                )
                BreakdownRow(
                    number: "4",
                    icon: "calendar",
                    iconColor: .green,
                    label: "Plazo elegido",
                    value: "\(result.plazoMeses) meses",
                    source: "Seleccionado por ti"
                )
            }

            // Coverage result
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cobertura de tu consumo CFE")
                        .font(.sunCaption)
                        .foregroundStyle(.textSecondary)
                    Text("\(Int(result.coberturaPct))% de tu factura")
                        .font(.sunHeading)
                        .foregroundStyle(.green)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 6)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: result.coberturaPct / 100)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 48, height: 48)
                    Text("\(Int(result.coberturaPct))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
            .padding(12)
            .background(Color.green.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(Color.surfaceGray)
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.sunCaption)
                    .foregroundStyle(.textPrimary)
                Text(source)
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            Text(value)
                .font(.sunCaption.weight(.bold))
                .foregroundStyle(.textPrimary)
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value). \(source)")
    }
}
