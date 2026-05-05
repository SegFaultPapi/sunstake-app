import SwiftUI

struct QuotaCalculatorView: View {
    @Environment(AppState.self) var appState
    @State private var facturaMXN: String = ""
    @State private var ubicacion: String = ""
    @State private var selectedTerm: PaymentTerm = .thirtySix
    @State private var showResult = false
    @State private var isCalculating = false
    @State private var result: QuotaResult? = nil

    var canCalculate: Bool {
        !facturaMXN.isEmpty && Double(facturaMXN) != nil && !ubicacion.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Calcula tu cuota solar")
                            .font(.sunTitle)
                        Text("La IA usa datos reales de NASA para calcular cuánto pagarías. Tú decides si te conviene.")
                            .font(.sunCaption)
                            .foregroundStyle(.textSecondary)
                        // HCAI: transparencia de fuente
                        Label("Cálculo realizado en tu dispositivo · Fuente: NASA POWER API", systemImage: "cpu")
                            .font(.caption2)
                            .foregroundStyle(.chainIndigo)
                            .padding(.top, 2)
                    }

                    // Input: Factura
                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Cuánto pagas de luz al mes?")
                            .font(.sunHeading)
                        HStack {
                            Text("$")
                                .foregroundStyle(.textSecondary)
                            TextField("1,200", text: $facturaMXN)
                                .keyboardType(.numberPad)
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                            Text("MXN")
                                .foregroundStyle(.textSecondary)
                        }
                        .padding()
                        .background(Color.surfaceGray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Monto de factura mensual en pesos")
                    }

                    // Input: Ubicación
                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Dónde está tu casa?")
                            .font(.sunHeading)
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.sunOrange)
                            TextField("Ciudad o código postal", text: $ubicacion)
                                .font(.sunBody)
                        }
                        .padding()
                        .background(Color.surfaceGray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Quick location chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["Guadalajara", "CDMX", "Monterrey", "Mérida", "Tijuana"], id: \.self) { city in
                                    Button {
                                        ubicacion = city
                                    } label: {
                                        Text(city)
                                            .font(.sunCaption.weight(.medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(ubicacion == city ? Color.sunOrange : Color.surfaceGray)
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
                            .font(.sunHeading)
                        HStack(spacing: 0) {
                            ForEach(PaymentTerm.allCases) { term in
                                Button {
                                    selectedTerm = term
                                } label: {
                                    Text(term.label)
                                        .font(.sunCaption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedTerm == term ? Color.sunOrange : Color.clear)
                                        .foregroundStyle(selectedTerm == term ? .white : .textSecondary)
                                }
                                .accessibilityLabel("Plazo \(term.label)\(selectedTerm == term ? ", seleccionado" : "")")
                            }
                        }
                        .background(Color.surfaceGray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("Plazos más largos = cuotas más bajas")
                            .font(.caption2)
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
                                .font(.sunHeading)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canCalculate ? Color.sunOrange : Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canCalculate || isCalculating)
                }
                .padding(24)
            }
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
