import Foundation

enum BlockchainError: LocalizedError {
    case invalidNetwork
    case rpcUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidNetwork:
            return "Red no permitida. Esta app funciona solo en Base Sepolia."
        case .rpcUnavailable:
            return "No pudimos conectarnos a Base Sepolia. Revisa tu conexion e intenta de nuevo."
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
