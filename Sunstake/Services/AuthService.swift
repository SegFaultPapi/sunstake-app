import Foundation

struct AuthSession {
    let email: String
    let fullName: String
}

enum AuthError: LocalizedError {
    case invalidEmail
    case invalidName
    case invalidOTP

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Ingresa un correo valido para continuar."
        case .invalidName:
            return "Necesitamos tu nombre completo para crear tu cuenta."
        case .invalidOTP:
            return "El codigo de acceso no es valido. Intenta de nuevo."
        }
    }
}

actor AuthService {
    func sendOTP(to email: String) async throws {
        guard email.contains("@") else { throw AuthError.invalidEmail }
        try await Task.sleep(nanoseconds: 350_000_000)
    }

    func loginWithOTP(email: String, otp: String) async throws -> AuthSession {
        guard email.contains("@") else { throw AuthError.invalidEmail }
        guard otp.count == 6 else { throw AuthError.invalidOTP }
        try await Task.sleep(nanoseconds: 350_000_000)
        let name = email.components(separatedBy: "@").first?.capitalized ?? "Usuario"
        return AuthSession(email: email, fullName: name)
    }

    func register(name: String, email: String) async throws -> AuthSession {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { throw AuthError.invalidName }
        guard email.contains("@") else { throw AuthError.invalidEmail }
        try await Task.sleep(nanoseconds: 350_000_000)
        return AuthSession(email: email, fullName: cleanName)
    }
}
