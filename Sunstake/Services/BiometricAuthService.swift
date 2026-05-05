import Foundation
import LocalAuthentication

enum BiometricAuthError: LocalizedError {
    case unavailable
    case failed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Tu dispositivo no tiene biometria activa. Usa tu PIN de 6 digitos."
        case .failed:
            return "No pudimos validar tu identidad. Intenta de nuevo."
        }
    }
}

struct BiometricAuthService {
    func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricAuthError.unavailable
        }

        let ok = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        if !ok {
            throw BiometricAuthError.failed
        }
    }
}
