import SwiftUI

struct QuotaCalculatorView: View {
    @Environment(AppState.self) var appState
    @State private var facturaMXN: String = ""
    @State private var ubicacion: String = ""
    @State private var selectedTerm: PaymentTerm = .thirtySix
    @State private var showResult = false
    @State private var isCalculating = false
    @State private var result: QuotaResult? = nil
    @State private var facturaEdited = false

    private let ciudadesDisponibles = [
        "Guadalajara", "CDMX", "Monterrey", "Mérida", "Tijuana",
        "Puebla", "León", "Querétaro", "San Luis Potosí", "Hermosillo"
    ]

    var facturaValida: Bool { Double(facturaMXN) != nil }
    var canCalculate: Bool { !facturaMXN.isEmpty && facturaValida && !ubicacion.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Calcula tu cuota solar")
                            .font(.dsTitle)
                        Text("La IA usa datos reales de NASA para calcular cuánto pagarías. Tú decides si te conviene.")
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                        // HCAI: transparencia de fuente
                        Label("Cálculo en tu dispositivo · Fuente: NASA POWER API", systemImage: "cpu")
                            .font(.dsCaption2)
                            .foregroundStyle(.chain500)
                            .padding(.top, DSSpacing.xs)
                    }

                    // Input: Factura
                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Cuánto pagas de luz al mes?")
                            .font(.dsHeading)
                        HStack {
                            Text("$")
                                .foregroundStyle(.textSecondary)
                            TextField("1,200", text: $facturaMXN)
                                .keyboardType(.numberPad)
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .onChange(of: facturaMXN) { _, _ in facturaEdited = true }
                            Text("MXN")
                                .foregroundStyle(.textSecondary)
                        }
                        .padding()
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Monto de factura mensual en pesos")

                        if facturaEdited && !facturaMXN.isEmpty && !facturaValida {
                            Label("Ingresa solo números", systemImage: "exclamationmark.circle.fill")
                                .font(.dsCaption2)
                                .foregroundStyle(.danger)
                                .transition(.opacity.animation(.easeInOut))
                        }
                    }

                    // Input: Ubicación
                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Dónde está tu casa?")
                            .font(.dsHeading)

                        Menu {
                            ForEach(ciudadesDisponibles, id: \.self) { city in
                                Button(city) { ubicacion = city }
                            }
                        } label: {
                            HStack {
                                Image(systemName: ubicacion.isEmpty ? "location" : "location.fill")
                                    .foregroundStyle(ubicacion.isEmpty ? .textSecondary : .secondary500)
                                Text(ubicacion.isEmpty ? "Elige tu ciudad" : ubicacion)
                                    .font(.dsBody)
                                    .foregroundStyle(ubicacion.isEmpty ? .textSecondary : .textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            }
                            .padding()
                            .background(Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityLabel("Seleccionar ciudad. \(ubicacion.isEmpty ? "Ninguna seleccionada" : "Ciudad: \(ubicacion)")")

                        // Quick chips para acceso rápido
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["Guadalajara", "CDMX", "Monterrey", "Mérida", "Tijuana"], id: \.self) { city in
                                    Button {
                                        ubicacion = city
                                    } label: {
                                        Text(city)
                                            .font(.dsCaption.weight(.medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(ubicacion == city ? Color.secondary500 : Color.surface)
                                            .foregroundStyle(ubicacion == city ? .white : .textPrimary)
                                            .clipShape(Capsule())
                                    }
                                    .accessibilityLabel("Seleccionar \(city)")
                                }
                            }
                        }
                    }

                    // Input: Plazo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plazo de pago")
                            .font(.dsHeading)
                        HStack(spacing: 0) {
                            ForEach(PaymentTerm.allCases) { term in
                                Button {
                                    selectedTerm = term
                                } label: {
                                    Text(term.label)
                                        .font(.dsCaption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedTerm == term ? Color.secondary500 : Color.clear)
                                        .foregroundStyle(selectedTerm == term ? .white : .textSecondary)
                                }
                                .accessibilityLabel("Plazo \(term.label)\(selectedTerm == term ? ", seleccionado" : "")")
                            }
                        }
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("Plazos más largos = cuotas más bajas")
                            .font(.dsCaption2)
                            .foregroundStyle(.textSecondary)
                    }

                    // CTA
                    Button {
                        calculate()
                    } label: {
                        HStack {
                            if isCalculating {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 4)
                            }
                            Text(isCalculating ? "Calculando..." : "Calcular mi cuota")
                                .font(.dsHeading)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canCalculate ? Color.secondary500 : Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canCalculate || isCalculating)
                }
                .padding(24)
            }
            .changeRoleButton()
            .navigationTitle("Sunstake")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showResult) {
                if let result {
                    QuotaResultView(result: result)
                }
            }
        }
    }

    private func calculate() {
        guard let monto = Double(facturaMXN) else { return }
        isCalculating = true
        // Simulate async on-device calculation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            result = appState.calculateQuota(consumoMXN: monto, ubicacion: ubicacion, plazo: selectedTerm)
            isCalculating = false
            showResult = true
        }
    }
}
