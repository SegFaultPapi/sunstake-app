import Foundation
import SwiftUI

// MARK: - Enums

enum UserRole {
    case beneficiary, investor, none
}

enum ConfidenceLevel: String {
    case alta = "Alta"
    case media = "Media"
    case baja = "Baja"

    var color: Color {
        switch self {
        case .alta: return .green
        case .media: return Color.orange
        case .baja: return .red
        }
    }
    var icon: String {
        switch self {
        case .alta: return "checkmark.circle.fill"
        case .media: return "exclamationmark.circle.fill"
        case .baja: return "questionmark.circle.fill"
        }
    }
    var detail: String {
        switch self {
        case .alta: return "Basado en datos NASA reales de tu zona"
        case .media: return "Usando promedios regionales estimados"
        case .baja: return "Datos limitados — considera ajustar manualmente"
        }
    }
}

enum TransactionState: Equatable {
    case idle
    case creatingContract
    case mintingTokens
    case confirming
    case success(txHash: String)
    case error(message: String)
    case processing
    case purchaseSuccess(txHash: String)

    var label: String {
        switch self {
        case .idle: return ""
        case .creatingContract: return "Creando contrato..."
        case .mintingTokens: return "Emitiendo tokens..."
        case .confirming: return "Confirmando en Base Network..."
        case .success: return "¡Proyecto publicado!"
        case .error(let msg): return msg
        case .processing: return "Procesando en Base Network..."
        case .purchaseSuccess: return "¡Inversión confirmada!"
        }
    }
    var isLoading: Bool {
        switch self {
        case .creatingContract, .mintingTokens, .confirming, .processing: return true
        default: return false
        }
    }
    var isSuccess: Bool {
        switch self {
        case .success, .purchaseSuccess: return true
        default: return false
        }
    }
    var txHash: String? {
        switch self {
        case .success(let h), .purchaseSuccess(let h): return h
        default: return nil
        }
    }
}

enum PaymentTerm: Int, CaseIterable, Identifiable {
    case twelve = 12, twentyFour = 24, thirtySix = 36
    var id: Int { rawValue }
    var label: String { "\(rawValue) meses" }
}

enum ProjectStatus {
    case open, funded, completed
}

// MARK: - Domain Models

struct QuotaResult {
    let cuotaMXN: Double
    let consumoKWh: Double
    let horasSol: Double
    let tamanoPanel: String
    let coberturaPct: Double
    let plazoMeses: Int
    let rendimientoInversorPct: Double
    let confianza: ConfidenceLevel
    let explicacion: String
    let ubicacion: String

    var cuotaUSDC: Double { cuotaMXN / 17.5 }
    var montoTotalMXN: Double { cuotaMXN * Double(plazoMeses) }
    var ahorroEstimadoMXN: Double { cuotaMXN * 0.45 }
}

struct SolarProject: Identifiable {
    let id: UUID
    let ciudad: String
    let estado: String
    let rendimientoAnualPct: Double
    let plazoTotalMeses: Int
    let mesesRestantes: Int
    let porcentajeFinanciado: Double
    let co2ToneladasAnio: Double
    let kwhGeneradosAnio: Double
    let montoMinUSD: Double
    let montoTotalUSD: Double
    let contractAddress: String
    let status: ProjectStatus
    let beneficiario: String

    var mesesPagados: Int { plazoTotalMeses - mesesRestantes }
    var rendimientoMensualPct: Double { rendimientoAnualPct / 12 / 100 }
    var isOpen: Bool { status == .open }
}

struct Payment: Identifiable {
    let id: UUID
    let fecha: Date
    let montoMXN: Double
    let montoUSDC: Double
    let txHash: String

    var txHashCorto: String { "\(txHash.prefix(6))...\(txHash.suffix(4))" }
}

struct YieldEntry: Identifiable {
    let id: UUID
    let fecha: Date
    let montoUSDC: Double
    let montoMXN: Double
    let proyecto: String
    let txHash: String

    var txHashCorto: String { "\(txHash.prefix(6))...\(txHash.suffix(4))" }
}

// MARK: - Mock Data

extension SolarProject {
    static let mockProjects: [SolarProject] = [
        SolarProject(
            id: UUID(), ciudad: "Guadalajara", estado: "JAL",
            rendimientoAnualPct: 9.2, plazoTotalMeses: 36, mesesRestantes: 8,
            porcentajeFinanciado: 0.78, co2ToneladasAnio: 1.2, kwhGeneradosAnio: 2_400,
            montoMinUSD: 1, montoTotalUSD: 2_250,
            contractAddress: "0x7f3a4b2c9d1e8f5a0c3b6d9e2f1a4b7c0d3e6f9a",
            status: .open, beneficiario: "Ana R."
        ),
        SolarProject(
            id: UUID(), ciudad: "Monterrey", estado: "NL",
            rendimientoAnualPct: 8.7, plazoTotalMeses: 24, mesesRestantes: 13,
            porcentajeFinanciado: 0.45, co2ToneladasAnio: 0.9, kwhGeneradosAnio: 1_800,
            montoMinUSD: 1, montoTotalUSD: 1_800,
            contractAddress: "0x3a9f1e7d4c2b8a5f0e3c6b9d2a1f4e7c0b3d6a9f",
            status: .open, beneficiario: "María L."
        ),
        SolarProject(
            id: UUID(), ciudad: "Mérida", estado: "YUC",
            rendimientoAnualPct: 10.1, plazoTotalMeses: 36, mesesRestantes: 22,
            porcentajeFinanciado: 0.31, co2ToneladasAnio: 1.5, kwhGeneradosAnio: 3_000,
            montoMinUSD: 1, montoTotalUSD: 2_800,
            contractAddress: "0x1c4e7a0f3b6d9e2c5a8f1b4d7e0c3f6a9b2e5d8f",
            status: .open, beneficiario: "Carlos M."
        ),
        SolarProject(
            id: UUID(), ciudad: "Querétaro", estado: "QRO",
            rendimientoAnualPct: 8.5, plazoTotalMeses: 24, mesesRestantes: 0,
            porcentajeFinanciado: 1.0, co2ToneladasAnio: 0.8, kwhGeneradosAnio: 1_600,
            montoMinUSD: 1, montoTotalUSD: 1_500,
            contractAddress: "0x9d2f5a8e1b4c7f0d3e6a9b2c5f8a1e4b7d0c3f6a",
            status: .funded, beneficiario: "Jorge P."
        )
    ]
}

extension Payment {
    static let mockPayments: [Payment] = [
        Payment(id: UUID(), fecha: Date().addingTimeInterval(-86_400 * 2),
                montoMXN: 850, montoUSDC: 48.57,
                txHash: "0x3f4a2b9c1d8e5f0a3c6b9d2e1f4a7b0c3d6e9f2a"),
        Payment(id: UUID(), fecha: Date().addingTimeInterval(-86_400 * 32),
                montoMXN: 850, montoUSDC: 48.57,
                txHash: "0x2b9c4a1d7e3f0c5a8b2d6e9f1c4a7b0e3d6c9f2b"),
        Payment(id: UUID(), fecha: Date().addingTimeInterval(-86_400 * 62),
                montoMXN: 850, montoUSDC: 48.57,
                txHash: "0x1d7e3c9a5f2b0e4a8c1d6b9e3f7a0c4e7b2d5a8f"),
        Payment(id: UUID(), fecha: Date().addingTimeInterval(-86_400 * 92),
                montoMXN: 850, montoUSDC: 48.57,
                txHash: "0x4e9f2a7c0b5d8a1e4f7c2b9d5e0a3f6b9c2e5a8d"),
        Payment(id: UUID(), fecha: Date().addingTimeInterval(-86_400 * 122),
                montoMXN: 850, montoUSDC: 48.57,
                txHash: "0x5a1b4e8c2f7d0a3e6c9b2d5f8a1c4b7e0d3f6a9c")
    ]
}

extension YieldEntry {
    static let mockYields: [YieldEntry] = [
        YieldEntry(id: UUID(), fecha: Date().addingTimeInterval(-86_400 * 5),
                   montoUSDC: 3.84, montoMXN: 67.2,
                   proyecto: "Guadalajara, JAL",
                   txHash: "0x7c2a9f1e4b8d3c6a0e5f2b9d4c7a1e8f3b6d9c2a"),
        YieldEntry(id: UUID(), fecha: Date().addingTimeInterval(-86_400 * 35),
                   montoUSDC: 3.84, montoMXN: 67.2,
                   proyecto: "Guadalajara, JAL",
                   txHash: "0x8d3b0f2e5c9a4d7b1f4c8e2a6b9d3f0c5e8a2b5d"),
        YieldEntry(id: UUID(), fecha: Date().addingTimeInterval(-86_400 * 5),
                   montoUSDC: 1.31, montoMXN: 22.9,
                   proyecto: "Monterrey, NL",
                   txHash: "0x9e4c1a3f6d0b5e8c2f5a9d3b7c0e4f1a6b9c3d6e"),
        YieldEntry(id: UUID(), fecha: Date().addingTimeInterval(-86_400 * 65),
                   montoUSDC: 3.84, montoMXN: 67.2,
                   proyecto: "Guadalajara, JAL",
                   txHash: "0x0f5d2b4a7e1c6f9b3e6a0d4c8b1f5e2a9d3c6b0f")
    ]
}
