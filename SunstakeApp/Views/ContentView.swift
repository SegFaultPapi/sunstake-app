import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else {
                switch appState.userRole {
                case .beneficiary:
                    BeneficiaryRootView()
                case .investor:
                    InvestorRootView()
                case .none:
                    RoleSelectionView()
                }
            }
        }
        .animation(.easeInOut, value: appState.hasCompletedOnboarding)
        .animation(.easeInOut, value: appState.userRole == .none)
    }
}

// MARK: - Beneficiary root tab navigator

struct BeneficiaryRootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            BeneficiaryHomeView()
                .tabItem {
                    Label("Mi Panel", systemImage: "sun.max.fill")
                }
            AccountView()
                .tabItem {
                    Label("Cuenta", systemImage: "person.circle")
                }
        }
        .accentColor(.sunOrange)
    }
}

// Decides beneficiary's first screen based on whether they have an active project
struct BeneficiaryHomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.activeProject != nil {
            BeneficiaryDashboardView()
        } else {
            QuotaCalculatorView()
        }
    }
}

// MARK: - Investor root tab navigator

struct InvestorRootView: View {
    var body: some View {
        TabView {
            ProjectExplorerView()
                .tabItem {
                    Label("Proyectos", systemImage: "bolt.circle.fill")
                }
            YieldHistoryView()
                .tabItem {
                    Label("Rendimientos", systemImage: "chart.line.uptrend.xyaxis")
                }
            AccountView()
                .tabItem {
                    Label("Cuenta", systemImage: "person.circle")
                }
        }
        .accentColor(.chainIndigo)
    }
}

// MARK: - Shared account view

struct AccountView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section("Tu cuenta de pagos") {
                    HStack {
                        Label("Dirección wallet", systemImage: "wallet.pass")
                        Spacer()
                        Text("0x71a3...f9c2")
                            .font(.sunCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    HStack {
                        Label("Balance USDC", systemImage: "dollarsign.circle")
                        Spacer()
                        Text("$124.50 USDC")
                            .font(.sunCaption.weight(.semibold))
                            .foregroundStyle(.chainIndigo)
                    }
                }
                Section("Seguridad") {
                    Label("Face ID activo", systemImage: "faceid")
                        .foregroundStyle(.green)
                    Label("Contraseña PIN", systemImage: "lock")
                }
                Section("Notificaciones") {
                    Toggle("Pagos confirmados", isOn: .constant(true))
                    Toggle("Rendimientos recibidos", isOn: .constant(true))
                }
                Section {
                    Button(role: .destructive) {
                        appState.userRole = .none
                        appState.hasCompletedOnboarding = false
                    } label: {
                        Label("Cerrar sesión", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Mi cuenta")
        }
    }
}
