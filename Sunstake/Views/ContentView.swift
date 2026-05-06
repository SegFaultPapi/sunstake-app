import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        ZStack(alignment: .top) {
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

            // Toast layer — rendered above TabView and NavigationStack
            if appState.isShowingToast, let toast = appState.activeToast {
                ToastBannerView(toast: toast, onDismiss: { appState.dismissToast() })
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.isShowingToast)
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
        if !appState.activeProjects.isEmpty {
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
    @Environment(AccessibilityPreferences.self) var accessibility

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
                        Label("ID de tu cuenta", systemImage: "wallet.pass")
                        Spacer()
                        Text(shortAddress(appState.walletAddress))
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    HStack {
                        Label("Tipo de cuenta", systemImage: "shippingbox")
                        Spacer()
                        Text(appState.walletProviderLabel.isEmpty ? "—" : appState.walletProviderLabel)
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    HStack {
                        Label("Saldo disponible", systemImage: "dollarsign.circle")
                        Spacer()
                        if appState.isLoadingBalance {
                            ProgressView()
                                .controlSize(.mini)
                        } else if appState.balanceError != nil {
                            Button {
                                Task { await appState.refreshWalletBalance() }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reintentar")
                                }
                                .font(.dsCaption.weight(.semibold))
                                .foregroundStyle(.warning)
                            }
                            .accessibilityLabel("No se pudo leer el saldo. Toca para reintentar.")
                        } else {
                            HStack(spacing: 6) {
                                Text(String(format: "$%.2f USD", appState.walletBalanceUSDC))
                                    .font(.dsCaption.weight(.semibold))
                                    .foregroundStyle(.chain500)
                                Button {
                                    Task { await appState.refreshWalletBalance() }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.dsCaption2)
                                        .foregroundStyle(.textSecondary)
                                }
                                .accessibilityLabel("Actualizar saldo")
                            }
                        }
                    }
                    HStack {
                        Label("Red activa", systemImage: "link")
                        Spacer()
                        Text(appState.networkConfig.networkLabel)
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }
                Section("Accesibilidad") {
                    // Tamaño de letra
                    HStack {
                        Label("Tamaño de letra", systemImage: "textformat.size")
                        Spacer()
                        Picker("", selection: Bindable(accessibility).fontSize) {
                            ForEach(AccessibilityPreferences.FontSizeOption.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Tamaño de letra: \(accessibility.fontSize.rawValue)")
                    }

                    // Modo oscuro
                    HStack {
                        Label("Apariencia", systemImage: "circle.lefthalf.filled")
                        Spacer()
                        Picker("", selection: Bindable(accessibility).colorScheme) {
                            ForEach(AccessibilityPreferences.AppColorScheme.allCases) { opt in
                                Label(opt.rawValue, systemImage: opt.icon).tag(opt)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Apariencia: \(accessibility.colorScheme.rawValue)")
                    }

                    // Daltonismo
                    HStack {
                        Label("Daltonismo", systemImage: "eye.fill")
                        Spacer()
                        Picker("", selection: Bindable(accessibility).colorBlindMode) {
                            ForEach(AccessibilityPreferences.ColorBlindMode.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Modo para daltonismo: \(accessibility.colorBlindMode.rawValue)")
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
            .refreshable {
                await appState.refreshWalletBalance()
            }
            .task {
                await appState.refreshWalletBalance()
            }
            .task {
                // Auto-refresh every 15 s while the tab is visible
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 15_000_000_000)
                    guard !Task.isCancelled else { break }
                    await appState.refreshWalletBalance()
                }
            }
        }
    }

    private func shortAddress(_ value: String) -> String {
        guard value.count > 10 else { return value.isEmpty ? "—" : value }
        return "\(value.prefix(6))...\(value.suffix(4))"
    }
}
