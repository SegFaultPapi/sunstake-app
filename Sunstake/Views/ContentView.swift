import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !appState.isLoggedIn {
                AuthView()
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
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: appState.isLoggedIn)
        .animation(.easeInOut(duration: 0.25), value: appState.userRole == .none)
    }
}

// MARK: - Beneficiary root tab navigator

struct BeneficiaryRootView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        TabView {
            BeneficiaryHomeView()
                .tabItem {
                    Label("Mi Panel", systemImage: "sun.max.fill")
                }

            BeneficiaryFinancingView()
                .tabItem {
                    Label("Mi Proyecto", systemImage: "chart.pie.fill")
                }

            AccountView()
                .tabItem {
                    Label("Cuenta", systemImage: "person.circle")
                }
        }
        .accentColor(.secondary500)
    }
}

// Decides beneficiary's first screen based on whether they have an active project
struct BeneficiaryHomeView: View {
    @Environment(AppState.self) var appState

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
        .accentColor(.chain500)
    }
}

// MARK: - Shared account view

struct AccountView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        NavigationStack {
            List {
                Section("Tu cuenta de pagos") {
                    HStack {
                        Label("Usuario", systemImage: "person.circle")
                        Spacer()
                        Text(appState.userName.isEmpty ? "—" : appState.userName)
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    HStack {
                        Label("Correo", systemImage: "envelope")
                        Spacer()
                        Text(appState.userEmail.isEmpty ? "—" : appState.userEmail)
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                            .lineLimit(1)
                    }
                    HStack {
                        Label("Dirección wallet", systemImage: "wallet.pass")
                        Spacer()
                        Text(shortAddress(appState.walletAddress))
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    HStack {
                        Label("Proveedor wallet", systemImage: "shippingbox")
                        Spacer()
                        Text(appState.walletProviderLabel.isEmpty ? "—" : appState.walletProviderLabel)
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    HStack {
                        Label("Balance USDC", systemImage: "dollarsign.circle")
                        Spacer()
                        Text(String(format: "$%.2f USDC", appState.walletBalanceUSDC))
                            .font(.dsCaption.weight(.semibold))
                            .foregroundStyle(.chain500)
                    }
                    HStack {
                        Label("Red activa", systemImage: "link")
                        Spacer()
                        Text(appState.networkConfig.networkLabel)
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }
                Section("Seguridad") {
                    Label(appState.hasBiometricAccess ? "Face ID / Touch ID activo" : "Biometría no disponible", systemImage: "faceid")
                        .foregroundStyle(appState.hasBiometricAccess ? .success : .warning)
                    Label("PIN de 6 digitos", systemImage: "lock")
                }
                Section("Notificaciones") {
                    Toggle("Pagos confirmados", isOn: .constant(true))
                    Toggle("Rendimientos recibidos", isOn: .constant(true))
                }
                Section {
                    Button {
                        appState.changeRole()
                    } label: {
                        Label("Cambiar rol", systemImage: "arrow.left.arrow.right")
                    }
                }
                Section {
                    Button(role: .destructive) {
                        appState.logout()
                    } label: {
                        Label("Cerrar sesión", systemImage: "arrow.right.square")
                    }
                }
            }
            .changeRoleButton()
            .navigationTitle("Mi cuenta")
        }
    }

    private func shortAddress(_ value: String) -> String {
        guard value.count > 10 else { return value.isEmpty ? "—" : value }
        return "\(value.prefix(6))...\(value.suffix(4))"
    }
}
