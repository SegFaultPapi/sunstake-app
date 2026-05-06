import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Input data for the quota explanation prompt

struct QuotaExplanationInput {
    let cuotaMXN: Double
    let consumoKWh: Double
    let horasSol: Double
    let tamanoPanel: String
    let coberturaPct: Double
    let plazoMeses: Int
    let ubicacion: String
    let rendimientoPct: Double
    let confianza: String
}

// MARK: - On-device AI explanation service using Foundation Models (iOS 18+)

enum FoundationModelsService {

    /// Genera una explicación en lenguaje natural de la cuota solar usando Apple Intelligence.
    /// En dispositivos con iOS < 18 o sin Apple Intelligence devuelve `nil` y el caller
    /// muestra el texto estático de respaldo.
    static func generateQuotaExplanation(for input: QuotaExplanationInput) async -> String? {
        guard #available(iOS 18, *) else { return nil }
        return await generateWithFoundationModels(input: input)
    }

    @available(iOS 18, *)
    private static func generateWithFoundationModels(input: QuotaExplanationInput) async -> String? {
#if canImport(FoundationModels)
        do {
            let session = LanguageModelSession()
            let prompt = buildPrompt(for: input)
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
#if DEBUG
            print("[Sunstake] Foundation Models error: \(error.localizedDescription)")
#endif
            return nil
        }
#else
        return nil
#endif
    }

    private static func buildPrompt(for input: QuotaExplanationInput) -> String {
        """
        Eres un asesor de energía solar para México. Explica en 2-3 oraciones cortas, \
        en español sencillo (sin tecnicismos), por qué la cuota mensual es \
        $\(Int(input.cuotaMXN)) MXN.

        Datos del cálculo:
        - Consumo eléctrico mensual: \(Int(input.consumoKWh)) kWh
        - Horas de sol diarias en \(input.ubicacion): \(String(format: "%.1f", input.horasSol)) h (fuente NASA)
        - Tamaño del panel: \(input.tamanoPanel)
        - Cobertura estimada del consumo: \(Int(input.coberturaPct))%
        - Plazo de financiamiento: \(input.plazoMeses) meses
        - Rendimiento proyectado para inversores: \(String(format: "%.1f", input.rendimientoPct))%
        - Nivel de confianza del modelo: \(input.confianza)

        Reglas:
        - Usa lenguaje amigable y empático, como si hablaras con Ana, una ama de casa.
        - No repitas todos los números, menciona solo los más relevantes.
        - Termina con una frase breve de confianza: el cálculo usa datos reales de NASA.
        - Máximo 60 palabras.
        """
    }
}
