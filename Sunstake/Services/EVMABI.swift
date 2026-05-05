import Foundation

/// Codificador/decodificador ABI minimo para los tipos que usa Sunstake:
/// `uint256`, `address`, `string` y arrays dinamicos `address[]`.
///
/// HCAI #4 Verifiable trust: el calldata generado aqui es 100% determinista
/// y se puede inspeccionar en Basescan, igual que cualquier wallet de hardware.
///
/// Limitaciones conscientes del MVP:
/// - `uint256` se representa como `UInt64` (suficiente para USDC 6 decimales hasta ~1.8e13 USDC).
/// - No usa `BigInt`: todos los montos se padden a 32 bytes con ceros a la izquierda.
enum EVMABI {
    enum Param {
        case address(String)
        case uint256(UInt64)
        case string(String)
    }

    /// Empaqueta un selector + parametros en calldata hex (`0x...`).
    static func encodeCall(selector: String, params: [Param]) -> String {
        let cleanSelector = selector.hasPrefix("0x") ? String(selector.dropFirst(2)) : selector
        let body = encodeParams(params)
        return "0x" + cleanSelector + body
    }

    /// Codifica una lista de parametros (heads + tails) sin selector.
    static func encodeParams(_ params: [Param]) -> String {
        let headSize = 32 * params.count
        var heads: [String] = []
        var tails: [String] = []
        var tailOffset = headSize

        for param in params {
            switch param {
            case .address(let addr):
                heads.append(encodeAddress(addr))
            case .uint256(let value):
                heads.append(encodeUInt256(value))
            case .string(let str):
                heads.append(encodeUInt256(UInt64(tailOffset)))
                let encoded = encodeStringTail(str)
                tails.append(encoded)
                tailOffset += encoded.count / 2
            }
        }

        return heads.joined() + tails.joined()
    }

    // MARK: - Codificadores tipo

    /// Padea una direccion (40 hex chars con o sin 0x) a 32 bytes (64 hex chars).
    static func encodeAddress(_ address: String) -> String {
        let normalized = address.lowercased()
        let body: String = normalized.hasPrefix("0x") ? String(normalized.dropFirst(2)) : normalized
        return String(repeating: "0", count: 64 - body.count) + body
    }

    /// Codifica `UInt64` a 32 bytes hex.
    static func encodeUInt256(_ value: UInt64) -> String {
        let hex = String(value, radix: 16)
        return String(repeating: "0", count: 64 - hex.count) + hex
    }

    /// Codifica un string dinamico (sin offset; ese se calcula afuera): length (32B) + bytes UTF-8 padded a multiplo de 32.
    private static func encodeStringTail(_ string: String) -> String {
        let bytes = Array(string.utf8)
        let length = encodeUInt256(UInt64(bytes.count))
        let dataHex = bytes.map { String(format: "%02x", $0) }.joined()
        let paddingNeeded = (32 - bytes.count % 32) % 32
        let padding = String(repeating: "0", count: paddingNeeded * 2)
        return length + dataHex + padding
    }

    // MARK: - Decodificadores

    /// Convierte un resultado hex (`0x` + 64 chars) a `UInt64`. Trunca a los 16 hex menos significativos.
    static func decodeUInt256(_ hex: String) -> UInt64 {
        var clean = hex.lowercased()
        if clean.hasPrefix("0x") { clean.removeFirst(2) }
        guard !clean.isEmpty else { return 0 }
        if clean.count > 16 { clean = String(clean.suffix(16)) }
        return UInt64(clean, radix: 16) ?? 0
    }

    /// Extrae la direccion de un word de 32 bytes (los ultimos 20 bytes = 40 hex chars con prefijo 0x).
    static func decodeAddress(fromWord word: String) -> String {
        var clean = word.lowercased()
        if clean.hasPrefix("0x") { clean.removeFirst(2) }
        let suffix = String(clean.suffix(40))
        return "0x" + suffix
    }

    /// Decodifica un `address[]` (return value de `getProjects()`).
    /// Layout: offset(32B)=0x20 | length(32B) | n × address(32B).
    static func decodeAddressArray(_ hex: String) -> [String] {
        var clean = hex.lowercased()
        if clean.hasPrefix("0x") { clean.removeFirst(2) }
        guard clean.count >= 128 else { return [] }
        let lengthWord = String(clean.dropFirst(64).prefix(64))
        let count = Int(EVMABI.decodeUInt256(lengthWord))
        var addresses: [String] = []
        addresses.reserveCapacity(count)
        let dataStart = 128
        for i in 0..<count {
            let start = dataStart + i * 64
            guard start + 64 <= clean.count else { break }
            let word = String(clean.dropFirst(start).prefix(64))
            addresses.append(decodeAddress(fromWord: word))
        }
        return addresses
    }

    /// Resultado de `SolarProject.getProjectMetadata()`.
    struct SolarProjectDecodedMetadata {
        let beneficiaryLowercasedAddress: String
        let cuotaMensualMicro: UInt64
        let montoTotalMicro: UInt64
        let plazoMeses: UInt64
        let rendimientoBps: UInt64
        let mesesPagados: UInt64
        /// Campo Solidity `activo`.
        let proyectoActivoOnChain: Bool
        let ciudad: String
        let estado: String
        let paymentSplitterLowercasedAddress: String
        let ownershipTransferLowercasedAddress: String
    }

    /// Decodifica el retorno ABI de `SolarProject.getProjectMetadata()`.
    ///
    /// Layout del hex crudo (sin `0x`) que devuelve `eth_call`:
    /// ```
    /// word 0  : 0x20  — outer-tuple offset (Metadata es tipo dinámico porque contiene strings)
    /// word 1  : beneficiario (address, 20 bytes alineados a derecha)
    /// word 2  : cuotaMensualUSDC (uint256)
    /// word 3  : montoTotalUSDC   (uint256)
    /// word 4  : plazoMeses       (uint256)
    /// word 5  : rendimientoBps   (uint256)
    /// word 6  : mesesPagados     (uint256)
    /// word 7  : fechaInicio      (uint256, ignorado por la app)
    /// word 8  : activo           (bool)
    /// word 9  : offset ciudad    (relativo al inicio de datos del struct = byte 32)
    /// word 10 : offset estado    (relativo al inicio de datos del struct = byte 32)
    /// word 11 : paymentSplitter  (address)
    /// word 12 : ownershipTransfer(address)
    /// word 13+: tails de las strings (length + UTF-8 padded a 32 bytes)
    /// ```
    static func decodeSolarProjectMetadata(hex raw: String) -> SolarProjectDecodedMetadata? {
        var hexFull = raw.lowercased()
        if hexFull.hasPrefix("0x") { hexFull.removeFirst(2) }
        // Mínimo: 1 outer word + 12 struct-head words + 2 string-length words = 15 words
        guard hexFull.count >= 13 * 64 else { return nil }

        // word(i) lee el i-ésimo word del struct, saltando el outer-offset en word 0.
        func word(_ i: Int) -> Substring {
            let startIdx = hexFull.index(hexFull.startIndex, offsetBy: (i + 1) * 64)
            let endIdx = hexFull.index(startIdx, offsetBy: 64)
            return hexFull[startIdx..<endIdx]
        }

        func subUInt64(_ hexWord: Substring) -> UInt64 {
            EVMABI.decodeUInt256("0x" + hexWord)
        }

        let beneficiario = EVMABI.decodeAddress(fromWord: String(word(0))).lowercased()
        let cuota = subUInt64(word(1))
        let total = subUInt64(word(2))
        let plazo = subUInt64(word(3))
        let rendimientoBps = subUInt64(word(4))
        let mesesPagados = subUInt64(word(5))
        // word(6) = fechaInicio — no se usa en la app

        let activoTail = word(7).suffix(2)
        let proyectoActivo = activoTail != "00"

        // Los offsets de ciudad/estado son relativos al inicio del struct (byte 32 del hex completo).
        // Se suma 32 para convertir a offset absoluto dentro de hexFull.
        let structBaseBytes = 32
        let offCiudad = Int(subUInt64(word(8))) + structBaseBytes
        let offEstado  = Int(subUInt64(word(9))) + structBaseBytes
        guard offCiudad > 0, offEstado > 0 else { return nil }

        guard
            let ciudad = decodeAbiString(fromHexNoPrefix: hexFull, byteOffset: offCiudad),
            let estado = decodeAbiString(fromHexNoPrefix: hexFull, byteOffset: offEstado)
        else {
            return nil
        }

        let splitter  = EVMABI.decodeAddress(fromWord: String(word(10))).lowercased()
        let ownership = EVMABI.decodeAddress(fromWord: String(word(11))).lowercased()

        return SolarProjectDecodedMetadata(
            beneficiaryLowercasedAddress: beneficiario,
            cuotaMensualMicro: cuota,
            montoTotalMicro: total,
            plazoMeses: plazo,
            rendimientoBps: rendimientoBps,
            mesesPagados: mesesPagados,
            proyectoActivoOnChain: proyectoActivo,
            ciudad: ciudad,
            estado: estado,
            paymentSplitterLowercasedAddress: splitter,
            ownershipTransferLowercasedAddress: ownership
        )
    }

    private static func decodeAbiString(fromHexNoPrefix hex: String, byteOffset: Int) -> String? {
        guard byteOffset >= 0 else { return nil }
        let startHex = hex.index(hex.startIndex, offsetBy: byteOffset * 2)
        guard hex.distance(from: hex.startIndex, to: startHex) + 64 <= hex.count else { return nil }

        let lenWordEnd = hex.index(startHex, offsetBy: 64)
        let lenHexStr = hex[startHex..<lenWordEnd]
        let contentByteLen = Int(EVMABI.decodeUInt256("0x" + lenHexStr))
        guard contentByteLen >= 0, contentByteLen < 65_536 else { return nil }

        let contentHexStart = lenWordEnd
        let contentHexCount = contentByteLen * 2
        guard hex.distance(from: hex.startIndex, to: contentHexStart) + contentHexCount <= hex.count else {
            return nil
        }

        var bytes = [UInt8]()
        bytes.reserveCapacity(contentByteLen)
        var idx = contentHexStart
        for _ in 0..<contentByteLen {
            let next = hex.index(idx, offsetBy: 2)
            guard let b = UInt8(hex[idx..<next], radix: 16) else { return nil }
            bytes.append(b)
            idx = next
        }
        return String(bytes: bytes, encoding: .utf8)
    }
}
