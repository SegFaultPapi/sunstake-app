import SwiftUI

private enum AuthMode: String, CaseIterable {
    case login    = "Iniciar sesión"
    case register = "Registrarse"
}

struct AuthView: View {
    @Environment(AppState.self) var appState

    @State private var mode: AuthMode = .login

    // Campos compartidos
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    // Solo registro
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var showConfirm = false

    // Feedback
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var faceIDLoading = false

    private var canSubmit: Bool {
        switch mode {
        case .login:
            return email.contains("@") && !password.isEmpty
        case .register:
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
                && email.contains("@")
                && password.count >= 6
                && password == confirmPassword
        }
    }

    private var passwordMismatch: Bool {
        mode == .register && !confirmPassword.isEmpty && password != confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xl) {

                // Brand header
                brandHeader

                // Mode selector
                Picker("Modo de acceso", selection: $mode.animation(.easeInOut(duration: 0.25))) {
                    ForEach(AuthMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Seleccionar modo: iniciar sesión o registrarse")

                // Form
                VStack(spacing: DSSpacing.sm) {
                    if mode == .register {
                        AuthField(
                            icon: "person",
                            placeholder: "Tu nombre completo",
                            text: $name,
                            isSecure: false
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    AuthField(
                        icon: "envelope",
                        placeholder: "Correo electrónico",
                        text: $email,
                        isSecure: false,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )

                    PasswordField(
                        placeholder: mode == .login ? "Contraseña" : "Contraseña (mín. 6 caracteres)",
                        password: $password,
                        show: $showPassword
                    )

                    if mode == .register {
                        PasswordField(
                            placeholder: "Confirmar contraseña",
                            password: $confirmPassword,
                            show: $showConfirm,
                            isError: passwordMismatch
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        if passwordMismatch {
                            Label("Las contraseñas no coinciden", systemImage: "exclamationmark.circle.fill")
                                .font(.dsCaption2)
                                .foregroundStyle(.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, DSSpacing.xs)
                                .transition(.opacity)
                        }
                    }
                }

                // Error banner
                if let error = errorMessage {
                    HStack(spacing: DSSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.danger)
                        Text(error)
                            .font(.dsFootnote)
                            .foregroundStyle(.danger)
                    }
                    .padding(DSSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.danger.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // CTA principal
                Button { submit() } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(mode == .login ? "Iniciar sesión" : "Crear cuenta")
                                .font(.dsHeading)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canSubmit ? Color.secondary500 : Color.gray.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
                }
                .disabled(!canSubmit || isLoading)
                .accessibilityLabel(mode == .login ? "Iniciar sesión" : "Crear cuenta")

                // Face ID (solo login)
                if mode == .login {
                    VStack(spacing: DSSpacing.md) {
                        HStack {
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                            Text("o continuar con")
                                .font(.dsCaption2)
                                .foregroundStyle(.textSecondary)
                                .fixedSize()
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                        }

                        Button { loginWithFaceID() } label: {
                            HStack(spacing: DSSpacing.sm) {
                                if faceIDLoading {
                                    ProgressView().tint(.secondary500)
                                } else {
                                    Image(systemName: "faceid")
                                        .font(.title3)
                                        .foregroundStyle(.secondary500)
                                }
                                Text("Entrar con Face ID")
                                    .font(.dsHeading)
                                    .foregroundStyle(.secondary500)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.secondary500.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.md)
                                    .stroke(Color.secondary500.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(faceIDLoading)
                        .accessibilityLabel("Iniciar sesión con Face ID")
                    }
                    .transition(.opacity)
                }

                // HCAI: privacy notice
                HStack(alignment: .top, spacing: DSSpacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.chain500)
                    Text("Tus datos se procesan en tu dispositivo. Nunca compartimos tu información financiera con terceros.")
                        .font(.dsCaption2)
                        .foregroundStyle(.textSecondary)
                }
                .padding(DSSpacing.sm)
                .background(Color.chain500.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm))

            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.top, DSSpacing.xl)
            .padding(.bottom, DSSpacing.xxl)
            .animation(.easeInOut(duration: 0.25), value: mode)
            .animation(.easeInOut(duration: 0.2), value: errorMessage)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    // MARK: - Brand header

    private var brandHeader: some View {
        VStack(spacing: DSSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.primary500.opacity(0.2))
                    .frame(width: 72, height: 72)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary500)
            }
            Text("Sunstake")
                .font(.dsTitle)
                .foregroundStyle(.textPrimary)
            Text(mode == .login ? "Bienvenido de nuevo" : "Crea tu cuenta gratuita")
                .font(.dsSubhead)
                .foregroundStyle(.textSecondary)
                .animation(.easeInOut, value: mode)
        }
    }

    // MARK: - Actions

    private func submit() {
        errorMessage = nil
        isLoading = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            isLoading = false
            switch mode {
            case .login:
                appState.login(email: email, name: "")
            case .register:
                appState.register(name: name.trimmingCharacters(in: .whitespaces), email: email)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func loginWithFaceID() {
        faceIDLoading = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            faceIDLoading = false
            appState.login(email: "demo@sunstake.mx", name: "Usuario Demo")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - AuthField

private struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.textSecondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(.dsBody)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(DSSpacing.md)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
    }
}

// MARK: - PasswordField

private struct PasswordField: View {
    let placeholder: String
    @Binding var password: String
    @Binding var show: Bool
    var isError: Bool = false

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "lock")
                .font(.body)
                .foregroundStyle(isError ? .danger : .textSecondary)
                .frame(width: 20)
            Group {
                if show {
                    TextField(placeholder, text: $password)
                } else {
                    SecureField(placeholder, text: $password)
                }
            }
            .font(.dsBody)
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            Button {
                show.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: show ? "eye.slash" : "eye")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            .accessibilityLabel(show ? "Ocultar contraseña" : "Mostrar contraseña")
        }
        .padding(DSSpacing.md)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(isError ? Color.danger.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
