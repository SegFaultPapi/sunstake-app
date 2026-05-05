import Foundation

enum BlockchainError: LocalizedError {
    case invalidNetwork
    case rpcUnavailable
    case invalidAddress
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidNetwork:
            return "Red no permitida. Esta app funciona solo en Base Sepolia."
        case .rpcUnavailable:
            return "No pudimos conectarnos a Base Sepolia. Revisa tu conexion e intenta de nuevo."
        case .invalidAddress:
            return "La direccion de la cuenta no es valida."
        case .invalidResponse:
            return "Respuesta invalida de la red. Intenta de nuevo en unos segundos."
        }
    }
}

actor BlockchainService {
    private let config: NetworkConfig

    init(config: NetworkConfig = .baseSepolia) {
        self.config = config
    }

    func ensureBaseSepolia() async throws {
        let chainId = try await fetchChainId()
        guard chainId == config.chainHex.lowercased() else {
            throw BlockchainError.invalidNetwork
        }
    }

    func publishProject() async throws -> String {
        try await ensureBaseSepolia()
        try await Task.sleep(nanoseconds: 900_000_000)
        return Self.mockTxHash(prefix: "aa")
    }

    func purchaseTokens() async throws -> String {
        try await ensureBaseSepolia()
        try await Task.sleep(nanoseconds: 900_000_000)
        return Self.mockTxHash(prefix: "bb")
    }

    func payMonthlyQuota() async throws -> String {
        try await ensureBaseSepolia()
        try await Task.sleep(nanoseconds: 900_000_000)
        return Self.mockTxHash(prefix: "cc")
    }

    /// Consulta on-chain el balance de USDC de una direccion en Base.
    /// Llama `balanceOf(address)` (selector 0x70a08231) sobre el ERC-20 USDC.
    /// USDC tiene 6 decimales, asi que devolvemos el valor humano (1.0 = 1 USDC).
    func fetchUSDCBalance(address: String) async throws -> Double {
        let normalized = address.lowercased()
        guard normalized.hasPrefix("0x"), normalized.count == 42 else {
            throw BlockchainError.invalidAddress
        }

        let addressHex = String(normalized.dropFirst(2))
        // 0x70a08231 + address padded a 32 bytes (24 ceros)
        let data = "0x70a08231" + String(repeating: "0", count: 24) + addressHex

        let raw = try await callBalance(
            to: config.usdcAddress,
            data: data
        )

        return Self.parseUSDCAmount(hex: raw)
    }

    private func callBalance(to: String, data: String) async throws -> String {
        if let value = try await ethCall(url: config.rpcURL, to: to, data: data) {
            return value
        }
        if let value = try await ethCall(url: config.fallbackRPCURL, to: to, data: data) {
            return value
        }
        throw BlockchainError.rpcUnavailable
    }

    private func ethCall(url: URL, to: String, data: String) async throws -> String? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_call",
            "params": [
                ["to": to, "data": data],
                "latest"
            ],
            "id": 1
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            let parsed = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
            return parsed?["result"] as? String
        } catch {
            return nil
        }
    }

    /// Convierte un resultado hex (`0x` + 64 caracteres) a un `Double` con los 6 decimales de USDC.
    private static func parseUSDCAmount(hex: String) -> Double {
        var clean = hex.lowercased()
        if clean.hasPrefix("0x") {
            clean.removeFirst(2)
        }
        guard !clean.isEmpty else { return 0 }
        // Truncamos a 16 hex chars (~64 bits) por seguridad: USDC 6 decimales soporta saldos enormes en UInt64.
        if clean.count > 16 {
            clean = String(clean.suffix(16))
        }
        guard let raw = UInt64(clean, radix: 16) else { return 0 }
        return Double(raw) / 1_000_000.0
    }

    private func fetchChainId() async throws -> String {
        if let value = try await callChainId(url: config.rpcURL) {
            return value
        }
        if let value = try await callChainId(url: config.fallbackRPCURL) {
            return value
        }
        throw BlockchainError.rpcUnavailable
    }

    private func callChainId(url: URL) async throws -> String? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 6
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = """
        {"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}
        """.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return (payload?["result"] as? String)?.lowercased()
        } catch {
            return nil
        }
    }

    private static func mockTxHash(prefix: String) -> String {
        let tail = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(62)
        return "0x\(prefix)\(tail)"
    }
}
