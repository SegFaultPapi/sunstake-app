import Foundation

/// Transaccion sin firmar lista para enviarse a la red.
/// Todas las cantidades en wei (gas) o unidades nativas (`value`).
struct UnsignedEVMTx: Sendable {
    let from: String
    let to: String
    let data: String // hex `0x...`
    let value: UInt64
    let nonce: UInt64
    let gasLimit: UInt64
    let gasPrice: UInt64
    let chainId: Int
}

/// Abstraccion del firmante de transacciones EVM.
/// Permite que `BlockchainService` no dependa directamente del SDK de Privy
/// y facilita testear con mocks.
protocol EVMSigner: Sendable {
    /// Firma y broadcastea la transaccion. Retorna el tx hash (`0x...`).
    func sendTransaction(_ tx: UnsignedEVMTx) async throws -> String
}
