import SwiftUI

// MARK: - AuthView (2-step OTP flow)
//
// Flujo unificado de acceso (HCAI: baja carga cognitiva, modelo mental claro):
//   Step 1 — Email: el usuario ingresa su correo.
//   Step 2 — Code:  el usuario ingresa el código de 6 dígitos enviado por correo.
//
// Privy unifica login y registro: si el correo no existe, se crea una cuenta
// nueva automáticamente. Por eso no hay toggle "Iniciar sesión / Registrarse".
//
// El nombre se infiere del correo (AuthService.loginWithOTP) y el usuario
// puede editarlo más tarde en su perfil.

private enum AuthStep {
    case email
    case code
}

struct AuthView: View {
    @Environment(AppState.self) var appState

    // Flow state
    @State private var step: AuthStep = .email
    @State private var email = ""
    @State private var otpCode = ""

    // Feedback
    @State private var isLoading = false
    @State private var isSendingCode = false
    @State private var faceIDLoading = false
    @State private var errorMessage: String? = nil

    // Resend cooldown (anti-spam): 60s después de cada envío.
    @State private var resendCooldown: Int = 0
    private let resendCooldownSeconds = 60

    private var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex)
            .evaluate(with: email.trimmingCharacters(in: .whitespaces))
    }

    private var isCompleteOTP: Bool {
        otpCode.count == 6
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                brandHeader

                ZStack {
                    if step == .email {
                        emailStep
                            .transition(stepTransition(forward: false))
                    } else {
                        codeStep
                            .transition(stepTransition(forward: true))
                    }
                }
                .animation(.easeInOut(duration: 0.28), value: step)

                if let error = errorMessage {
                    errorBanner(error)
                }

                privacyFootnote
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.top, DSSpacing.xl)
            .padding(.bottom, DSSpacing.xxl)
            .animation(.easeInOut(duration: 0.2), value: errorMessage)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    // MARK: - Step 1: Email

    @ViewBuilder
    private var emailStep: some View {
        VStack(spacing: DSSpacing.lg) {
            VStack(spacing: DSSpacing.xs) {
                Text("Tu correo")
                    .font(.dsHeading)
                    .foregroundStyle(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Te enviaremos un código de 6 dígitos para acceder.")
                    .font(.dsFootnote)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AuthField(
                icon: "envelope",
                placeholder: "tucorreo@ejemplo.com",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            .submitLabel(.continue)
            .onSubmit {
                if isValidEmail { sendCodeAndAdvance() }
            }

            Button { sendCodeAndAdvance() } label: {
                primaryButtonLabel(
                    title: "Continuar",
                    isLoading: isSendingCode,
                    isEnabled: isValidEmail
                )
            }
            .disabled(!isValidEmail || isSendingCode)
            .accessibilityLabel("Continuar al paso de verificación")

            dividerLabel("o continuar con")

            Button { loginWithFaceID() } label: {
                HStack(spacing: DSSpacing.sm) {
                    if faceIDLoading {
                        ProgressView().tint(.secondary500)
                    } else {
                        Image(systemName: "faceid")
                            .font(.title3)
                            .foregroundStyle(.secondary500)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Acceso demo rápido")
                            .font(.dsHeading)
                            .foregroundStyle(.secondary500)
                        Text("Entra con la cuenta de prueba")
                            .font(.dsCaption2)
                            .foregroundStyle(.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DSSpacing.md)
                .frame(height: 56)
                .background(Color.secondary500.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.md)
                        .stroke(Color.secondary500.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(faceIDLoading)
            .accessibilityLabel("Acceso demo rápido con cuenta de prueba")
        }
    }

    // MARK: - Step 2: Code

    @ViewBuilder
    private var codeStep: some View {
        VStack(spacing: DSSpacing.lg) {
            // Encabezado: "Código enviado a tu@correo.com" + cambiar.
            HStack(alignment: .center, spacing: DSSpacing.sm) {
                Button {
                    goBackToEmailStep()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.dsCaption.weight(.semibold))
                        Text("Cambiar correo")
                            .font(.dsCaption.weight(.medium))
                    }
                    .foregroundStyle(.secondary500)
                }
                .accessibilityLabel("Volver para cambiar el correo")
                Spacer()
            }

            VStack(spacing: DSSpacing.xs) {
                Text("Ingresa tu código")
                    .font(.dsHeading)
                    .foregroundStyle(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                (
                    Text("Te enviamos un código a ")
                        .foregroundStyle(.textSecondary)
                    + Text(email)
                        .foregroundStyle(.textPrimary)
                        .fontWeight(.semibold)
                )
                .font(.dsFootnote)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            OTPInputView(
                code: $otpCode,
                isError: errorMessage != nil,
                onComplete: { _ in
                    if !isLoading { submitCode() }
                }
            )

            Button { submitCode() } label: {
                primaryButtonLabel(
                    title: "Verificar y entrar",
                    isLoading: isLoading,
                    isEnabled: isCompleteOTP
                )
            }
            .disabled(!isCompleteOTP || isLoading)
            .accessibilityLabel("Verificar código y entrar")

            // Reenviar con cooldown.
            HStack(spacing: 6) {
                Text("¿No recibiste el código?")
                    .font(.dsCaption)
                    .foregroundStyle(.textSecondary)

                if resendCooldown > 0 {
                    Text("Reenviar en \(resendCooldown)s")
                        .font(.dsCaption.weight(.medium))
                        .foregroundStyle(.textSecondary)
                        .accessibilityLabel("Podrás reenviar en \(resendCooldown) segundos")
                } else {
                    Button {
                        resendCode()
                    } label: {
                        Text(isSendingCode ? "Reenviando..." : "Reenviar código")
                            .font(.dsCaption.weight(.semibold))
                            .foregroundStyle(.secondary500)
                    }
                    .disabled(isSendingCode)
                    .accessibilityLabel("Reenviar código por correo")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Shared subviews

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
            Text("Energía solar tokenizada")
                .font(.dsSubhead)
                .foregroundStyle(.textSecondary)
        }
    }

    private var privacyFootnote: some View {
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

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.danger)
            Text(message)
                .font(.dsFootnote)
                .foregroundStyle(.danger)
        }
        .padding(DSSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.danger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm))
        .transition(.opacity.combined(with: .move(edge: .top)))
        .accessibilityElement(children: .combine)
    }

    private func dividerLabel(_ label: String) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
            Text(label)
                .font(.dsCaption2)
                .foregroundStyle(.textSecondary)
                .fixedSize()
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
        }
    }

    private func primaryButtonLabel(title: String, isLoading: Bool, isEnabled: Bool) -> some View {
        Group {
            if isLoading {
                ProgressView().tint(.white)
            } else {
                Text(title).font(.dsHeading)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(isEnabled ? Color.secondary500 : Color.gray.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
    }

    // MARK: - Transitions

    private func stepTransition(forward: Bool) -> AnyTransition {
        let edge: Edge = forward ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge == .trailing ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    // MARK: - Actions

    private func sendCodeAndAdvance() {
        let cleanEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard NSPredicate(
            format: "SELF MATCHES %@",
            #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        ).evaluate(with: cleanEmail) else {
            errorMessage = "Ingresa un correo válido para continuar."
            return
        }

        errorMessage = nil
        isSendingCode = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            defer { isSendingCode = false }
            do {
                try await appState.sendAccessCode(email: cleanEmail)
                email = cleanEmail
                otpCode = ""
                step = .code
                startResendCooldown()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                errorMessage = error.localizedDescription
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private func resendCode() {
        guard resendCooldown == 0, !isSendingCode else { return }
        errorMessage = nil
        isSendingCode = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            defer { isSendingCode = false }
            do {
                try await appState.sendAccessCode(email: email)
                otpCode = ""
                startResendCooldown()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                errorMessage = error.localizedDescription
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private func submitCode() {
        guard isCompleteOTP, !isLoading else { return }
        errorMessage = nil
        isLoading = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            defer { isLoading = false }
            do {
                try await appState.login(email: email, otp: otpCode)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                errorMessage = error.localizedDescription
                otpCode = ""
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private func goBackToEmailStep() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        errorMessage = nil
        otpCode = ""
        step = .email
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
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private func startResendCooldown() {
        resendCooldown = resendCooldownSeconds
        Task { @MainActor in
            while resendCooldown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if resendCooldown > 0 { resendCooldown -= 1 }
            }
        }
    }
}

// MARK: - OTPInputView
//
// 6 cuadros separados que muestran el código.
// Por debajo hay un único TextField numérico oculto (alpha 0.001) que captura
// teclado y soporta autofill `.oneTimeCode` + paste de 6 dígitos.
// El cuadro activo se resalta con borde acentuado.

private struct OTPInputView: View {
    @Binding var code: String
    let length: Int = 6
    var isError: Bool = false
    var onComplete: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden input: captura teclado, soporta autofill y paste.
            TextField("", text: Binding(
                get: { code },
                set: { newValue in
                    let digits = newValue.filter { $0.isNumber }
                    let limited = String(digits.prefix(length))
                    code = limited
                    if limited.count == length {
                        onComplete(limited)
                    }
                }
            ))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isFocused)
            .opacity(0.001)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Código de verificación de 6 dígitos")
            .accessibilityHint("Ingresa el código que recibiste por correo")

            // Cuadros visuales.
            HStack(spacing: DSSpacing.sm) {
                ForEach(0..<length, id: \.self) { idx in
                    OTPBox(
                        value: character(at: idx),
                        isActive: idx == code.count && isFocused,
                        isError: isError
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }

    private func character(at index: Int) -> String {
        guard index < code.count else { return "" }
        let i = code.index(code.startIndex, offsetBy: index)
        return String(code[i])
    }
}

private struct OTPBox: View {
    let value: String
    let isActive: Bool
    let isError: Bool

    var body: some View {
        Text(value)
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .stroke(borderColor, lineWidth: isActive || isError ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isActive)
            .animation(.easeInOut(duration: 0.15), value: isError)
    }

    private var borderColor: Color {
        if isError { return .danger }
        if isActive { return .secondary500 }
        return Color.gray.opacity(0.2)
    }
}

// MARK: - AuthField

private struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
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
