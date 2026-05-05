import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sun.max.fill",
            iconColor: .sunYellow,
            title: "Energía solar para todos",
            subtitle: "Accede a paneles solares pagando cómodas cuotas mensuales. Sin pago inicial. Sin complicaciones.",
            accentText: "Reduce tu factura CFE más del 50%"
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .chainIndigo,
            title: "Invierte con impacto real",
            subtitle: "Compra una fracción de un proyecto solar desde $1 USD y recibe rendimiento mensual verificable en blockchain.",
            accentText: "10% anual · trazabilidad total · desde $1 USD"
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            iconColor: .green,
            title: "Transparencia garantizada",
            subtitle: "Cada peso que pagas o recibes queda registrado con un código de verificación público. La IA te explica cada decisión.",
            accentText: "La IA sugiere. Tú decides. Blockchain verifica."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { i in
                    OnboardingPageView(page: pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicators
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? Color.sunOrange : Color.gray.opacity(0.3))
                        .frame(width: i == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 24)

            // CTA
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    appState.hasCompletedOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Siguiente" : "Comenzar")
                    .font(.sunHeading)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.sunOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .accessibilityLabel(currentPage < pages.count - 1 ? "Siguiente página" : "Comenzar app")
        }
        .background(Color.white.ignoresSafeArea())
    }
}

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let accentText: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(page.iconColor)
            }
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.textPrimary)

                Text(page.subtitle)
                    .font(.sunBody)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.textSecondary)
                    .padding(.horizontal, 8)

                Text(page.accentText)
                    .font(.sunCaption.weight(.semibold))
                    .foregroundStyle(.sunOrange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.sunOrange.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}
