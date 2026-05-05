import Foundation
import PrivySDK

enum PrivyClientError: LocalizedError {
    case missingConfiguration
    case unauthenticated

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Falta configurar Privy. Define privyAppId y privyClientId en Sunstake/Configuration/Secrets.swift."
        case .unauthenticated:
            return "Tu sesion no esta autenticada. Inicia sesion nuevamente."
        }
    }
}

@MainActor
final class PrivyClient {
    private var privy: Privy?

    private func configuredPrivy() throws -> Privy {
        if let privy {
            return privy
        }

        let appId = Secrets.privyAppId.trimmingCharacters(in: .whitespacesAndNewlines)
        let clientId = Secrets.privyClientId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !appId.isEmpty, !clientId.isEmpty else {
            throw PrivyClientError.missingConfiguration
        }

        let config = PrivyConfig(
            appId: appId,
            appClientId: clientId,
            loggingConfig: .init(logLevel: .none)
        )
        let instance = PrivySdk.initialize(config: config)
        self.privy = instance
        return instance
    }

    private func ensureReady() async throws -> Privy {
        let privy = try configuredPrivy()
        _ = await privy.getAuthState()
        return privy
    }

    func sendEmailCode(to email: String) async throws {
        let privy = try await ensureReady()
        try await privy.email.sendCode(to: email)
    }

    func loginWithEmailCode(email: String, code: String) async throws {
        let privy = try await ensureReady()
        _ = try await privy.email.loginWithCode(code, sentTo: email)
    }

    func createOrRestoreEthereumWalletAddress() async throws -> String {
        let privy = try await ensureReady()
        guard case .authenticated(let user) = await privy.getAuthState() else {
            throw PrivyClientError.unauthenticated
        }

        if let existingWallet = user.embeddedEthereumWallets.first {
            return existingWallet.address
        }

        let wallet = try await user.createEthereumWallet(allowAdditional: false)
        return wallet.address
    }

    func logout() async {
        guard let privy else { return }
        if case .authenticated(let user) = await privy.getAuthState() {
            await user.logout()
        }
    }
}
