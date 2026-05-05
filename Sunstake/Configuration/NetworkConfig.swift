import Foundation

enum AppEnvironment {
    case baseSepolia
}

struct NetworkConfig {
    let environment: AppEnvironment
    let chainId: Int
    let chainHex: String
    let chainName: String
    let rpcURL: URL
    let fallbackRPCURL: URL
    let baseScanBaseURL: URL
    let usdcAddress: String
    let factoryAddress: String
    let isTestnet: Bool

    /// Configuracion de Base Sepolia. La direccion del `SunstakeFactory` debe venir de `Secrets.sunstakeFactoryAddress`
    /// (output de `forge script ... Deploy.s.sol`).
    nonisolated(unsafe) static var baseSepolia: NetworkConfig {
        let trimmed = Secrets.sunstakeFactoryAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let factoryAddress: String
        if trimmed.isEmpty {
            factoryAddress = "0x0000000000000000000000000000000000000000"
        } else if trimmed.hasPrefix("0x") {
            factoryAddress = trimmed
        } else {
            factoryAddress = "0x" + trimmed
        }

        let apiKey = Secrets.alchemyApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let primaryURL: URL
        let fallbackURL: URL
        if apiKey.isEmpty {
            // Sin API key: nodo público como primario, demo de Alchemy como respaldo
            primaryURL  = URL(string: "https://sepolia.base.org")!
            fallbackURL = URL(string: "https://base-sepolia.g.alchemy.com/v2/demo")!
        } else {
            // Con API key: Alchemy como primario (sin rate-limit efectivo), nodo público de respaldo
            primaryURL  = URL(string: "https://base-sepolia.g.alchemy.com/v2/\(apiKey)")!
            fallbackURL = URL(string: "https://sepolia.base.org")!
        }

        return NetworkConfig(
            environment: .baseSepolia,
            chainId: 84_532,
            chainHex: "0x14a34",
            chainName: "Base Sepolia",
            rpcURL: primaryURL,
            fallbackRPCURL: fallbackURL,
            baseScanBaseURL: URL(string: "https://sepolia.basescan.org")!,
            usdcAddress: "0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f",
            factoryAddress: factoryAddress,
            isTestnet: true
        )
    }

    var networkLabel: String {
        isTestnet ? "\(chainName) (modo de prueba)" : chainName
    }

    func txExplorerURL(hash: String) -> URL? {
        baseScanBaseURL.appendingPathComponent("tx").appendingPathComponent(hash)
    }
}
