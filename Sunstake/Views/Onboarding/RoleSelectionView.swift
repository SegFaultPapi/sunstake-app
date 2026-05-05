import SwiftUI

struct RoleSelectionView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 90))
                        .foregroundStyle(.primary500)
                    Text("Sunstake")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("¿Cómo quieres usar Sunstake?")
                        .font(.dsBody)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 28)

                // Role tiles
                VStack(spacing: 16) {
                    RoleTile(
                        icon: "house.fill",
                        accentColor: .secondary500,
                        title: "Quiero paneles solares",
                        subtitle: "Paga cuotas mensuales y adquiere tu panel. La IA calcula tu cuota ideal.",
                        role: .beneficiary
                    )
                    RoleTile(
                        icon: "bolt.circle.fill",
                        accentColor: .chain500,
                        title: "Quiero invertir",
                        subtitle: "Compra fracciones desde $1 USD y recibe rendimiento mensual verificado.",
                        role: .investor
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Footer
                Text("Puedes cambiar tu rol después en Configuración")
                    .font(.dsCaption)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

private struct RoleTile: View {
    @Environment(AppState.self) var appState
    let icon: String
    let accentColor: Color
    let title: String
    let subtitle: String
    let role: UserRole
    @State private var isPressed = false

    var body: some View {
        Button {
            appState.userRole = role
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(accentColor.opacity(0.08))
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentColor.opacity(0.25), lineWidth: 1)

                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 70, weight: .regular))
                        .foregroundStyle(accentColor)
                    Spacer()
                    VStack(spacing: 5) {
                        Text(title)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(subtitle)
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { isPressed = $0 }, perform: {})
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
