import Foundation

/// Normaliza direcciones y hashes hex que vienen del RPC/Privy para URLs de explorers (evita enlaces invalidos).
enum EvmNormalize {
    /// `0x` + 40 caracteres hex (bytes20).
    static func canonicalAddress(_ raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        s = String(s.filter { !$0.isNewline })
        if s.hasPrefix("\""), s.hasSuffix("\""), s.count >= 3 {
            s = String(s.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        s = s.lowercased()
        if s.hasPrefix("0x") {
            s = String(s.dropFirst(2))
        }
        guard s.count == 40, s.range(of: #"^[0-9a-f]{40}$"#, options: .regularExpression) != nil else {
            return nil
        }
        return "0x" + s
    }

    /// Prefijo `0x` + 64 caracteres hex (hash de transaccion).
    static func canonicalTxHash(_ raw: String) -> String? {
        var h = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        h = String(h.filter { !$0.isNewline })
        if h.hasPrefix("\""), h.hasSuffix("\""), h.count >= 3 {
            h = String(h.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if !h.lowercased().hasPrefix("0x") {
            h = "0x" + h
        }
        h = h.lowercased()
        let body = String(h.dropFirst(2))
        guard h.count == 66, body.range(of: #"^[0-9a-f]{64}$"#, options: .regularExpression) != nil else {
            return nil
        }
        return h
    }

    /// URL `.../address/0x...` solo si la direccion es valida.
    static func basescanAddressURL(explorerBase: String, address: String) -> URL? {
        guard let a = canonicalAddress(address) else { return nil }
        let base = explorerBase.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)/address/\(a)")
    }

    /// URL `.../tx/0x...`
    static func basescanTxURL(explorerBase: String = "https://sepolia.basescan.org", txHash: String) -> URL? {
        guard let tx = canonicalTxHash(txHash) else { return nil }
        let base = explorerBase.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)/tx/\(tx)")
    }
}
