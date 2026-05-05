import SwiftUI

struct RoleSelectionView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.primary500)
                Text("Sunstake")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("¿Cómo quieres usar Sunstake?")
                    .font(.dsBody)
                    .foregroundStyle(.textSecondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 48)

            VStack(spacing: 16) {
                RoleCard(
                    icon: "house.fill",
                    iconColor: .secondary500,
                    title: "Quiero paneles solares",
                    subtitle: "Paga cómodas cuotas mensuales y adquiere tu panel poco a poco. La IA calcula tu cuota ideal.",
                    role: .beneficiary
                )
                RoleCard(
                    icon: "bolt.circle.fill",
                    iconColor: .chain500,
                    title: "Quiero invertir",
                    subtitle: "Compra fracciones de proyectos solares desde $1 USD y recibe rendimiento mensual verificado.",
                    role: .investor
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Text("Puedes cambiar tu rol después en Configuración")
                .font(.dsCaption)
                .foregroundStyle(.textSecondary)
                .padding(.bottom, 32)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

struct RoleCard: View {
    @Environment(AppState.self) var appState
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let role: UserRole
    @State private var isPressed = false

    var body: some View {
        Button {
            appState.userRole = role
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundStyle(iconColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.dsHeading)
                        .foregroundStyle(.textPrimary)
                    Text(subtitle)
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.textSecondary)
            }
            .padding(20)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(iconColor.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { isPressed = $0 }, perform: {})
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
