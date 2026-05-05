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
        // USDC de pruebas (TestnetERC20, 6 decimales) usado por el faucet de Aave en Base Sepolia.
        // Permite mintar montos grandes para demo. Cuando salgamos a Base Mainnet
        // hay que cambiar a 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 (USDC oficial de Circle).
        usdcAddress: "0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f",
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
