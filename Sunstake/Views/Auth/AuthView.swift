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
    @State private var otpCode = ""

    // Solo registro
    @State private var name = ""
    @State private var pinCode = ""

    // Feedback
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var faceIDLoading = false
    @State private var otpSent = false

    private var canSubmit: Bool {
        switch mode {
        case .login:
            return email.contains("@") && otpCode.count == 6
        case .register:
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
                && email.contains("@")
                && pinCode.count == 6
        }
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

                    if mode == .register {
                        AuthField(
                            icon: "lock",
                            placeholder: "PIN de 6 dígitos",
                            text: $pinCode,
                            isSecure: false,
                            keyboardType: .numberPad,
                            textContentType: .oneTimeCode
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        AuthField(
                            icon: "number.square",
                            placeholder: "Código de acceso (6 dígitos)",
                            text: $otpCode,
                            isSecure: false,
                            keyboardType: .numberPad,
                            textContentType: .oneTimeCode
                        )
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

                if mode == .login || mode == .register {
                    Button {
                        sendOTP()
                    } label: {
                        Text(otpSent ? "Reenviar codigo" : "Enviar codigo por correo")
                            .font(.dsCaption)
                            .foregroundStyle(.secondary500)
                    }
                    .disabled(isLoading || !email.contains("@"))
                    .accessibilityLabel("Enviar codigo de acceso por correo")
                }

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
                    Text("Tu cuenta de pagos se crea automáticamente al entrar. No necesitas saber de cripto ni guardar frases de seguridad.")
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
        Task {
            defer { isLoading = false }
            do {
                switch mode {
                case .login:
                    try await appState.login(email: email, otp: otpCode)
                case .register:
                    try await appState.register(
                        name: name.trimmingCharacters(in: .whitespaces),
                        email: email,
                        otp: pinCode
                    )
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func sendOTP() {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await appState.sendAccessCode(email: email)
                otpSent = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loginWithFaceID() {
        faceIDLoading = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            defer { faceIDLoading = false }
            do {
                try await appState.login(email: "demo@sunstake.mx", otp: "123456")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                errorMessage = error.localizedDescription
            }
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
