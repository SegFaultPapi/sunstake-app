import Foundation

enum BlockchainError: LocalizedError {
    case invalidNetwork
    case rpcUnavailable
    case invalidAddress
    case invalidResponse
    case rpcError(String)
    case factoryNotConfigured
    case transactionReverted
    case receiptTimeout
    case projectAddressesNotFound

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
        case .rpcError(let msg):
            return "Error del nodo RPC: \(msg)"
        case .factoryNotConfigured:
            return "Falta desplegar la factory o configura SUNSTAKE_FACTORY_ADDRESS en Secrets.swift (direccion de SunstakeFactory en Base Sepolia)."
        case .transactionReverted:
            return "La transaccion se revirtio en la red de prueba. Verifica Balance de ETH/USDC."
        case .receiptTimeout:
            return "No recibimos confirmacion a tiempo. Revisa tu saldo ETH y tu conexion."
        case .projectAddressesNotFound:
            return "Publicamos pero no encontramos direcciones en el resultado. Intenta de nuevo."
        }
    }
}

/// Resultado on-chain tras `SunstakeFactory.createProject`: las 3 direcciones necesarias para la UI y pagos futuros.
struct BlockchainPublishResult: Sendable {
    let txHash: String
    let solarProjectAddress: String
    let paymentSplitterAddress: String
    let ownershipTransferAddress: String
}

/// RPC JSON + calldata real hacia SunstakeFactory / SolarProject / PaymentSplitter / USDC.
final class BlockchainService: @unchecked Sendable {
    private let config: NetworkConfig

    init(config: NetworkConfig) {
        self.config = config
    }

    // MARK: - Selectores de funcion (calculados con `cast sig` en contracts/)

    private static let selectorCreateProject = "24b2316b"
    private static let selectorApprove = "095ea7b3"
    private static let selectorInvest = "2afcf480"
    private static let selectorPayMonthly = "49c8493c"
    private static let selectorGetProjects = "dcc60128"
    private static let selectorGetProjectMetadata = "1af9fd17"
    private static let selectorPorcentajeFinanciadoBps = "c78ccca5"
    private static let selectorProjectToBeneficiario = "b5f60be7"
    /// ERC-1155 balanceOf(address,uint256) — TOKEN_ID siempre es 1 en FractionToken
    private static let selectorBalanceOf = "00fdd58e"
    private static let fractionTokenId: UInt64 = 1

    /// keccak256("ProjectCreated(address,address,address,address,string,string,uint256,uint256,uint256)")
    private static let projectCreatedTopic0 =
        "0x62f46ec16d8e41682bc7f169a48073f8080d16c1dd622ffb1d5e70f184d47457"

    // MARK: - Red

    func ensureBaseSepolia() async throws {
        let chainId = try await fetchChainId()
        guard chainId == config.chainHex.lowercased() else {
            throw BlockchainError.invalidNetwork
        }
    }

    private func requireFactory() throws -> String {
        let f = config.factoryAddress.lowercased()
        guard f != "0x0000000000000000000000000000000000000000" else {
            throw BlockchainError.factoryNotConfigured
        }
        return config.factoryAddress
    }

    /// Direccion EVM normalizada (`0x` + 40 hex minusculas) o mejor esfuerzo si el RPC envia basura minima (espacios).
    static func canonicalEVMAddress(_ raw: String) -> String {
        let stripped = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let ok = EvmNormalize.canonicalAddress(stripped) {
            return ok
        }
        #if DEBUG
        print("[Sunstake] direccion EVM no valida despues del parse: prefijo=\(stripped.prefix(24))...")
        #endif
        let lower = stripped.lowercased()
        guard lower.hasPrefix("0x"), lower.count >= 42 else {
            return lower.hasPrefix("0x") ? lower : "0x" + lower
        }
        return lower
    }

    /// Catalogo desde `SunstakeFactory.getProjects()` + `getProjectMetadata` / `porcentajeFinanciadoBps` por fila.
    func fetchSolarProjectsForExplorer() async throws -> [SolarProject] {
        try await ensureBaseSepolia()
        let factory = try requireFactory()
        let rawList =
            try await ethCallHexResult(to: Self.canonicalEVMAddress(factory), data: "0x" + Self.selectorGetProjects)
        let solarAddrs = EVMABI.decodeAddressArray(rawList)
        if solarAddrs.isEmpty {
            return []
        }

        var rows: [SolarProject] = []
        rows.reserveCapacity(solarAddrs.count)
        try await withThrowingTaskGroup(of: SolarProject?.self) { group in
            for a in solarAddrs {
                let addr = Self.canonicalEVMAddress(a)
                group.addTask {
                    try await self.explorerRow(forSolar: addr)
                }
            }
            for try await row in group {
                if let row {
                    rows.append(row)
                }
            }
        }
        return rows.sorted {
            $0.ciudad.localizedCaseInsensitiveCompare($1.ciudad) == .orderedAscending
        }
    }

    /// Busca en `SunstakeFactory.getProjects()` el proyecto cuyo `beneficiario` coincide con `walletAddress`.
    /// Devuelve `nil` si el usuario no tiene ningun proyecto publicado.
    func fetchActiveProjectForBeneficiary(walletAddress: String) async throws -> SolarProject? {
        try await ensureBaseSepolia()
        let factory = try requireFactory()
        let canonicalFactory = Self.canonicalEVMAddress(factory)
        let rawList = try await ethCallHexResult(to: canonicalFactory, data: "0x" + Self.selectorGetProjects)
        let solarAddrs = EVMABI.decodeAddressArray(rawList)
        guard !solarAddrs.isEmpty else { return nil }

        let normalizedWallet = walletAddress.lowercased()

        for rawAddr in solarAddrs {
            let solarAddr = Self.canonicalEVMAddress(rawAddr)
            let calldata = EVMABI.encodeCall(
                selector: Self.selectorProjectToBeneficiario,
                params: [.address(solarAddr)]
            )
            let benefRaw = try await ethCallHexResult(to: canonicalFactory, data: calldata)
            let benefAddr = EVMABI.decodeAddress(fromWord: benefRaw).lowercased()
            if benefAddr == normalizedWallet {
                return try await explorerRow(forSolar: solarAddr)
            }
        }
        return nil
    }

    /// Para cada proyecto en la factory, consulta el balance ERC-1155 de `walletAddress`.
    /// Devuelve los proyectos donde el balance es > 0, junto con el monto invertido en USD.
    func fetchInvestedProjectsForWallet(walletAddress: String) async throws -> [(project: SolarProject, investedUSD: Double)] {
        try await ensureBaseSepolia()
        let factory = try requireFactory()
        let canonicalFactory = Self.canonicalEVMAddress(factory)
        let rawList = try await ethCallHexResult(to: canonicalFactory, data: "0x" + Self.selectorGetProjects)
        let solarAddrs = EVMABI.decodeAddressArray(rawList)
        guard !solarAddrs.isEmpty else { return [] }

        var results: [(project: SolarProject, investedUSD: Double)] = []

        try await withThrowingTaskGroup(of: (SolarProject, Double)?.self) { group in
            for rawAddr in solarAddrs {
                let solarAddr = Self.canonicalEVMAddress(rawAddr)
                group.addTask {
                    let calldata = EVMABI.encodeCall(
                        selector: Self.selectorBalanceOf,
                        params: [.address(walletAddress), .uint256(Self.fractionTokenId)]
                    )
                    let balRaw = try await self.ethCallHexResult(to: solarAddr, data: calldata)
                    let balanceMicro = EVMABI.decodeUInt256(balRaw)
                    guard balanceMicro > 0 else { return nil }
                    guard let project = try await self.explorerRow(forSolar: solarAddr) else { return nil }
                    let investedUSD = Double(balanceMicro) / Self.usdcScale
                    return (project, investedUSD)
                }
            }
            for try await pair in group {
                if let pair { results.append(pair) }
            }
        }
        return results
    }

    private func ethCallHexResult(to: String, data: String) async throws -> String {
        if let value = try await ethCall(url: config.rpcURL, to: to, data: data), !value.isEmpty {
            return value
        }
        if let value = try await ethCall(url: config.fallbackRPCURL, to: to, data: data), !value.isEmpty {
            return value
        }
        throw BlockchainError.rpcUnavailable
    }

    private func explorerRow(forSolar solar: String) async throws -> SolarProject? {
        let metaRaw = try await ethCallHexResult(to: solar, data: "0x" + Self.selectorGetProjectMetadata)
        guard let meta = EVMABI.decodeSolarProjectMetadata(hex: metaRaw) else {
            return nil
        }

        let bpsRaw = try await ethCallHexResult(to: solar, data: "0x" + Self.selectorPorcentajeFinanciadoBps)
        let fundedBps = EVMABI.decodeUInt256(bpsRaw)

        let plazo = Int(meta.plazoMeses)
        let pagados = Int(meta.mesesPagados)
        let mesesRestantes = max(0, plazo - pagados)
        let pctFin = min(1.0, Double(fundedBps) / 10_000.0)
        let montoTotalUSD = Double(meta.montoTotalMicro) / Self.usdcScale

        let status: ProjectStatus
        if !meta.proyectoActivoOnChain {
            status = .completed
        } else if pctFin >= 0.999 {
            status = .funded
        } else {
            status = .open
        }

        let benefBody = String(meta.beneficiaryLowercasedAddress.dropFirst(2).prefix(4))
        let beneficiarioLabel = benefBody.isEmpty ? "Beneficiario" : "Familia 0x\(benefBody)…"

        let co2 = max(0.5, min(2.5, montoTotalUSD / 2_250.0 * 1.5))
        let kwh = max(800, montoTotalUSD * 900)

        return SolarProject(
            id: SolarProject.deterministicId(contractAddress: solar),
            ciudad: meta.ciudad,
            estado: meta.estado,
            rendimientoAnualPct: Double(meta.rendimientoBps) / 100.0,
            plazoTotalMeses: plazo,
            mesesRestantes: mesesRestantes,
            porcentajeFinanciado: pctFin,
            co2ToneladasAnio: co2,
            kwhGeneradosAnio: kwh,
            montoMinUSD: 1,
            montoTotalUSD: montoTotalUSD,
            contractAddress: solar,
            paymentSplitterAddress: Self.canonicalEVMAddress(meta.paymentSplitterLowercasedAddress),
            status: status,
            beneficiario: beneficiarioLabel,
            cuotaMensualUSD: Double(meta.cuotaMensualMicro) / Self.usdcScale
        )
    }

    // MARK: - Publicar proyecto (beneficiario)

    func publishProject(
        cuotaUSDC: Double,
        montoTotalUSDC: Double,
        plazoMeses: Int,
        rendimientoAnualPct: Double,
        ciudad: String,
        estado: String,
        fromAddress: String,
        signer: EVMSigner
    ) async throws -> BlockchainPublishResult {
        try await ensureBaseSepolia()
        let factory = try requireFactory()

        let cuotaRaw = Self.usdcToRawUnits(cuotaUSDC)
        let totalRaw = Self.usdcToRawUnits(montoTotalUSDC)
        let plazo = UInt64(plazoMeses)
        let rendimientoBps = UInt64((rendimientoAnualPct * 100.0).rounded())

        let data = EVMABI.encodeCall(
            selector: Self.selectorCreateProject,
            params: [
                .uint256(cuotaRaw),
                .uint256(totalRaw),
                .uint256(plazo),
                .uint256(rendimientoBps),
                .string(ciudad),
                .string(estado)
            ]
        )

        let hash = try await sendContractTransaction(
            to: factory,
            data: data,
            from: fromAddress,
            signer: signer,
            fallbackGasLimit: 6_000_000
        )
        let receipt = try await waitForReceipt(txHash: hash)
        try ensureSuccessReceipt(receipt)
        guard let triple = Self.parseProjectCreatedLog(receipt: receipt, factoryAddress: factory) else {
            throw BlockchainError.projectAddressesNotFound
        }

        return BlockchainPublishResult(
            txHash: hash,
            solarProjectAddress: triple.solar,
            paymentSplitterAddress: triple.splitter,
            ownershipTransferAddress: triple.ownership
        )
    }

    // MARK: - Invertir (inversor)

    /// approve(USDC) + `SolarProject.invest`. Devuelve el hash de la transacción `invest`.
    func purchaseTokens(
        solarProjectAddress: String,
        amountUSDC: Double,
        fromAddress: String,
        signer: EVMSigner
    ) async throws -> String {
        try await ensureBaseSepolia()
        let spender = solarProjectAddress
        let amountRaw = Self.usdcToRawUnits(amountUSDC)

        let approveData = EVMABI.encodeCall(
            selector: Self.selectorApprove,
            params: [
                .address(spender),
                .uint256(amountRaw)
            ]
        )

        let approveHash = try await sendContractTransaction(
            to: config.usdcAddress,
            data: approveData,
            from: fromAddress,
            signer: signer,
            fallbackGasLimit: 120_000
        )
        let approveReceipt = try await waitForReceipt(txHash: approveHash)
        try ensureSuccessReceipt(approveReceipt)

        let investData = EVMABI.encodeCall(
            selector: Self.selectorInvest,
            params: [.uint256(amountRaw)]
        )

        let investHash = try await sendContractTransaction(
            to: solarProjectAddress,
            data: investData,
            from: fromAddress,
            signer: signer,
            fallbackGasLimit: 450_000
        )
        let investReceipt = try await waitForReceipt(txHash: investHash)
        try ensureSuccessReceipt(investReceipt)
        return investHash
    }

    // MARK: - Pago mensual (beneficiario)

    /// approve(USDC) + `PaymentSplitter.payMonthly`. Devuelve el hash de `payMonthly`.
    func payMonthlyQuota(
        paymentSplitterAddress: String,
        cuotaUSDC: Double,
        fromAddress: String,
        signer: EVMSigner
    ) async throws -> String {
        try await ensureBaseSepolia()
        let cuotaRaw = Self.usdcToRawUnits(cuotaUSDC)

        let approveData = EVMABI.encodeCall(
            selector: Self.selectorApprove,
            params: [
                .address(paymentSplitterAddress),
                .uint256(cuotaRaw)
            ]
        )

        let approveHash = try await sendContractTransaction(
            to: config.usdcAddress,
            data: approveData,
            from: fromAddress,
            signer: signer,
            fallbackGasLimit: 120_000
        )
        let approveReceipt = try await waitForReceipt(txHash: approveHash)
        try ensureSuccessReceipt(approveReceipt)

        let payData = "0x" + Self.selectorPayMonthly
        let payHash = try await sendContractTransaction(
            to: paymentSplitterAddress,
            data: payData,
            from: fromAddress,
            signer: signer,
            fallbackGasLimit: 900_000
        )
        let payReceipt = try await waitForReceipt(txHash: payHash)
        try ensureSuccessReceipt(payReceipt)
        return payHash
    }

    // MARK: - Saldo USDC

    func fetchUSDCBalance(address: String) async throws -> Double {
        let normalized = address.lowercased()
        guard normalized.hasPrefix("0x"), normalized.count == 42 else {
            throw BlockchainError.invalidAddress
        }

        let addressHex = String(normalized.dropFirst(2))
        let data = "0x70a08231" + String(repeating: "0", count: 24) + addressHex

        let raw = try await callBalance(to: config.usdcAddress, data: data)
        return Self.parseUSDCAmount(hex: raw)
    }

    // MARK: - Envio de transacciones

    private func sendContractTransaction(
        to: String,
        data: String,
        from: String,
        signer: EVMSigner,
        fallbackGasLimit: UInt64
    ) async throws -> String {
        let nonce = try await fetchTransactionCount(address: from)
        let gasPrice = try await fetchGasPrice()
        var gasLimit = try await estimateGas(from: from, to: to, data: data)
        if gasLimit == 0 {
            gasLimit = fallbackGasLimit
        } else {
            gasLimit = UInt64((Double(gasLimit) * 1.25).rounded())
            gasLimit = max(gasLimit, 80_000)
        }
        gasLimit = min(gasLimit, 12_000_000)

        let tx = UnsignedEVMTx(
            from: from,
            to: to,
            data: data,
            value: 0,
            nonce: nonce,
            gasLimit: gasLimit,
            gasPrice: gasPrice,
            chainId: config.chainId
        )
        return try await signer.sendTransaction(tx)
    }

    // MARK: - Receipt / logs

    private func waitForReceipt(txHash: String) async throws -> [String: Any] {
        for _ in 0..<90 {
            if let receipt = try await ethGetTransactionReceipt(hash: txHash), receipt["blockNumber"] != nil {
                return receipt
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        throw BlockchainError.receiptTimeout
    }

    private func ensureSuccessReceipt(_ receipt: [String: Any]) throws {
        let status = receipt["status"] as? String
        if let status, status != "0x1" {
            throw BlockchainError.transactionReverted
        }
    }

    private static func parseProjectCreatedLog(
        receipt: [String: Any],
        factoryAddress: String
    ) -> (solar: String, splitter: String, ownership: String)? {
        guard let logs = receipt["logs"] as? [[String: Any]] else { return nil }
        let factory = factoryAddress.lowercased()
        for log in logs {
            let addr = (log["address"] as? String)?.lowercased() ?? ""
            guard addr == factory else { continue }
            guard let topics = log["topics"] as? [String], topics.count >= 4 else { continue }
            guard topics[0].lowercased() == projectCreatedTopic0.lowercased() else { continue }
            let solarRaw = EVMABI.decodeAddress(fromWord: topics[1])
            let splitterRaw = EVMABI.decodeAddress(fromWord: topics[2])
            let ownershipRaw = EVMABI.decodeAddress(fromWord: topics[3])
            guard
                let solar = EvmNormalize.canonicalAddress(solarRaw),
                let splitter = EvmNormalize.canonicalAddress(splitterRaw),
                let ownership = EvmNormalize.canonicalAddress(ownershipRaw)
            else {
                continue
            }
            return (solar, splitter, ownership)
        }
        return nil
    }

    // MARK: - JSON-RPC

    private func fetchChainId() async throws -> String {
        if let value = try await rpcStringResult(url: config.rpcURL, method: "eth_chainId", params: []) {
            return value.lowercased()
        }
        if let value = try await rpcStringResult(url: config.fallbackRPCURL, method: "eth_chainId", params: []) {
            return value.lowercased()
        }
        throw BlockchainError.rpcUnavailable
    }

    private func fetchTransactionCount(address: String) async throws -> UInt64 {
        let result = try await rpcStringResultAny(
            method: "eth_getTransactionCount",
            params: [address, "pending"]
        )
        return try Self.parseHexUInt64(result)
    }

    private func fetchGasPrice() async throws -> UInt64 {
        let result = try await rpcStringResultAny(method: "eth_gasPrice", params: [])
        return try Self.parseHexUInt64(result)
    }

    private func estimateGas(from: String, to: String, data: String) async throws -> UInt64 {
        do {
            let result = try await rpcStringResultAny(
                method: "eth_estimateGas",
                params: [["from": from, "to": to, "data": data]]
            )
            return try Self.parseHexUInt64(result)
        } catch {
            return 0
        }
    }

    private func ethGetTransactionReceipt(hash: String) async throws -> [String: Any]? {
        let any = try await rpcResultAny(method: "eth_getTransactionReceipt", params: [hash])
        return any as? [String: Any]
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
        let result = try await rpcStringResult(
            url: url,
            method: "eth_call",
            params: [["to": to, "data": data], "latest"]
        )
        return result
    }

    private func rpcStringResultAny(method: String, params: [Any]) async throws -> String {
        if let v = try await rpcStringResult(url: config.rpcURL, method: method, params: params) {
            return v
        }
        if let v = try await rpcStringResult(url: config.fallbackRPCURL, method: method, params: params) {
            return v
        }
        throw BlockchainError.rpcUnavailable
    }

    private func rpcResultAny(method: String, params: [Any]) async throws -> Any? {
        if let v = try await rpcResult(url: config.rpcURL, method: method, params: params) {
            return v
        }
        if let v = try await rpcResult(url: config.fallbackRPCURL, method: method, params: params) {
            return v
        }
        throw BlockchainError.rpcUnavailable
    }

    private func rpcStringResult(url: URL, method: String, params: [Any]) async throws -> String? {
        let any = try await rpcResult(url: url, method: method, params: params)
        return any as? String
    }

    private func rpcResult(url: URL, method: String, params: [Any]) async throws -> Any? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }
        guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BlockchainError.invalidResponse
        }
        if let err = parsed["error"] as? [String: Any],
           let message = err["message"] as? String {
            throw BlockchainError.rpcError(message)
        }
        guard let result = parsed["result"] else { return nil }
        if result is NSNull {
            return nil
        }
        return result
    }

    // MARK: - Helpers numericos / USDC

    private static let usdcScale: Double = 1_000_000

    /// USDC tiene 6 decimales — convertimos desde flotante decimal con redondeo.
    private static func usdcToRawUnits(_ human: Double) -> UInt64 {
        let raw = (human * usdcScale).rounded()
        guard raw.isFinite, raw > 0, raw <= Double(UInt64.max) else { return 0 }
        return UInt64(raw)
    }

    private static func parseHexUInt64(_ hex: String) throws -> UInt64 {
        var clean = hex.lowercased()
        if clean.hasPrefix("0x") { clean.removeFirst(2) }
        guard let value = UInt64(clean, radix: 16) else {
            throw BlockchainError.invalidResponse
        }
        return value
    }

    /// Convierte un resultado hex (`0x` + 64 caracteres) a `Double` con los 6 decimales de USDC.
    private static func parseUSDCAmount(hex: String) -> Double {
        var clean = hex.lowercased()
        if clean.hasPrefix("0x") {
            clean.removeFirst(2)
        }
        guard !clean.isEmpty else { return 0 }
        if clean.count > 16 {
            clean = String(clean.suffix(16))
        }
        guard let raw = UInt64(clean, radix: 16) else { return 0 }
        return Double(raw) / usdcScale
    }
}
