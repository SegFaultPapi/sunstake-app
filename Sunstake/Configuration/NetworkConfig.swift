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

    nonisolated(unsafe) static let baseSepolia = NetworkConfig(
        environment: .baseSepolia,
        chainId: 84_532,
        chainHex: "0x14a34",
        chainName: "Base Sepolia",
        rpcURL: URL(string: "https://sepolia.base.org")!,
        fallbackRPCURL: URL(string: "https://base-sepolia.g.alchemy.com/v2/demo")!,
        baseScanBaseURL: URL(string: "https://sepolia.basescan.org")!,
        usdcAddress: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
        factoryAddress: "0x0000000000000000000000000000000000000000",
        isTestnet: true
    )

    var networkLabel: String {
        isTestnet ? "\(chainName) (modo de prueba)" : chainName
    }

    func txExplorerURL(hash: String) -> URL? {
        baseScanBaseURL.appendingPathComponent("tx").appendingPathComponent(hash)
    }
}
