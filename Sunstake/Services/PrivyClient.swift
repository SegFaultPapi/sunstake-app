import Foundation
import PrivySDK

enum PrivyClientError: LocalizedError {
    case missingConfiguration
    case unauthenticated
    case noEmbeddedWallet
    case transactionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Falta configurar Privy. Define privyAppId y privyClientId en Sunstake/Configuration/Secrets.swift."
        case .unauthenticated:
            return "Tu sesion no esta autenticada. Inicia sesion nuevamente."
        case .noEmbeddedWallet:
            return "Tu cuenta de pagos aun no esta lista. Cierra sesion e inicia nuevamente."
        case .transactionFailed(let msg):
            return "No pudimos firmar la transaccion: \(msg)"
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

    /// Firma y envia una transaccion EVM usando la wallet embebida del usuario actual.
    /// Esto le pide a Privy que firme con la clave en su Secure Enclave y broadcastee.
    /// Retorna el tx hash (`0x...`).
    func sendEthTransaction(
        from: String,
        to: String,
        data: String,
        value: UInt64,
        nonce: UInt64,
        gasLimit: UInt64,
        gasPrice: UInt64,
        chainId: Int,
        rpcUrl: String? = nil
    ) async throws -> String {
        let privy = try await ensureReady()
        guard case .authenticated(let user) = await privy.getAuthState() else {
            throw PrivyClientError.unauthenticated
        }
        guard let wallet = user.embeddedEthereumWallets.first else {
            throw PrivyClientError.noEmbeddedWallet
        }

        // Base Sepolia: pasar RPC opcional ayuda a que Privy resuelva la red en el simulador.
        await wallet.provider.switchChain(chainId: chainId, rpcUrl: rpcUrl)

        let unsigned = EthereumRpcRequest.UnsignedEthTransaction(
            from: from,
            to: to,
            nonce: .int(Int(nonce)),
            gasLimit: .int(Int(gasLimit)),
            gasPrice: .int(Int(gasPrice)),
            data: data,
            value: .int(Int(value)),
            chainId: .int(chainId)
        )

        let request = try EthereumRpcRequest.ethSendTransaction(transaction: unsigned)

        do {
            let raw = try await wallet.provider.request(request)
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let hash = EvmNormalize.canonicalTxHash(trimmed) else {
                return trimmed
            }
            return hash
        } catch {
            throw PrivyClientError.transactionFailed(error.localizedDescription)
        }
    }
}

/// Implementacion de `EVMSigner` que delega en `PrivyClient` para firmar.
struct PrivyEVMSigner: EVMSigner {
    private let privyClient: PrivyClient
    private let rpcURL: String?

    init(privyClient: PrivyClient, rpcURL: String? = nil) {
        self.privyClient = privyClient
        self.rpcURL = rpcURL
    }

    func sendTransaction(_ tx: UnsignedEVMTx) async throws -> String {
        let client = privyClient
        let rpcUrl = rpcURL
        return try await Task { @MainActor in
            try await client.sendEthTransaction(
                from: tx.from,
                to: tx.to,
                data: tx.data,
                value: tx.value,
                nonce: tx.nonce,
                gasLimit: tx.gasLimit,
                gasPrice: tx.gasPrice,
                chainId: tx.chainId,
                rpcUrl: rpcUrl
            )
        }.value
    }
}
