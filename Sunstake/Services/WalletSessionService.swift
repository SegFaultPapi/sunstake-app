import Foundation

struct WalletAccount: Equatable {
    let address: String
    let providerName: String
}

protocol EmbeddedWalletProvider {
    var displayName: String { get }
    func createOrRestoreWallet(for email: String) async throws -> WalletAccount
    func logout() async
}

enum WalletSessionError: LocalizedError {
    case invalidEmail

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "No pudimos crear tu cuenta de pagos. Verifica tu correo e intenta de nuevo."
        }
    }
}

struct MockEmbeddedWalletProvider: EmbeddedWalletProvider {
    let displayName: String = "Privy (simulado)"

    func createOrRestoreWallet(for email: String) async throws -> WalletAccount {
        guard email.contains("@") else {
            throw WalletSessionError.invalidEmail
        }
        try await Task.sleep(nanoseconds: 450_000_000)
        return WalletAccount(
            address: Self.walletAddress(from: email),
            providerName: displayName
        )
    }

    func logout() async {}

    private static func walletAddress(from email: String) -> String {
        let source = Array(email.lowercased().utf8)
        let bytes = source.isEmpty ? Array(repeating: UInt8(0), count: 20) : (0..<20).map { idx in
            source[idx % source.count]
        }
        return "0x" + bytes.map { String(format: "%02x", $0) }.joined()
    }
}

actor WalletSessionService {
    private let provider: EmbeddedWalletProvider

    init(provider: EmbeddedWalletProvider = MockEmbeddedWalletProvider()) {
        self.provider = provider
    }

    var providerName: String {
        provider.displayName
    }

    func createOrRestoreWallet(email: String) async throws -> WalletAccount {
        try await provider.createOrRestoreWallet(for: email)
    }

    func logout() async {
        await provider.logout()
    }
}
