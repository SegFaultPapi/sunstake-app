import SwiftUI

struct PurchaseFlowView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss
    let project: SolarProject

    @State private var currentStep = 1
    @State private var amount: Double = 50
    @State private var showBiometric = false

    private let totalSteps = 3

    var tokens: Int { Int(amount) }
    var monthlyYield: Double { amount * project.rendimientoMensualPct }
    var gasFeeUSD: Double = 0.02

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator — HCAI: clear progress, no surprises
                StepIndicator(
                    current: currentStep,
                    total: totalSteps,
                    labels: ["Monto", "Resumen", "Confirmación"]
                )
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 4)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch currentStep {
                        case 1: step1View
                        case 2: step2View
                        default: EmptyView()
                        }
                    }
                    .padding(24)
                }

                // Navigation buttons
                VStack(spacing: 10) {
                    if currentStep < 2 {
                        Button {
                            withAnimation { currentStep += 1 }
                        } label: {
                            Text("Continuar")
                                .font(.dsHeading)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.chain500)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        // Step 3: biometric confirmation
                        Button {
                            showBiometric = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "faceid")
                                    .font(.title3)
                                Text("Confirmar con Face ID")
                                    .font(.dsHeading)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.chain500)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .accessibilityLabel("Confirmar inversión de \(Int(amount)) dólares con Face ID")
                    }

                    if currentStep > 1 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            Text("Volver")
                                .font(.dsCaption.weight(.medium))
                                .foregroundStyle(.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Invertir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showBiometric) {
                BiometricConfirmationSheet(
                    title: "Confirmar inversión",
                    subtitle: "$\(Int(amount)) USDC · \(tokens) fracciones · \(project.ciudad), \(project.estado)"
                ) {
                    showBiometric = false
                    dismiss()
                    Task { await appState.purchaseTokens(montoUSD: amount, project: project) }
                }
            }
        }
    }

    // MARK: - Step 1: Select amount
    var step1View: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Paso 1 — Elige tu monto")
                    .font(.dsTitle)
                Text("\(project.ciudad), \(project.estado) · \(String(format: "%.1f", project.rendimientoAnualPct))% anual")
                    .font(.dsCaption)
                    .foregroundStyle(.textSecondary)
            }

            // Amount display
            VStack(spacing: DSSpacing.sm) {
                Text("$\(Int(amount)) USDC")
                    .font(.dsDisplay)
                    .foregroundStyle(.chain500)
                    .contentTransition(.numericText())
                Text("\(tokens) fracciones del proyecto")
                    .font(.dsSubhead)
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity)

            // Slider
            VStack(spacing: 8) {
                Slider(value: $amount, in: 1...500, step: 1)
                    .tint(.chain500)
                    .animation(.easeInOut(duration: 0.1), value: amount)
                    .accessibilityLabel("Monto de inversión: \(Int(amount)) dólares")

                HStack {
                    Text("Mín $1 USD")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                    Text("Máx $500 USD")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
            }

            // Quick amount chips
            HStack(spacing: 8) {
                ForEach([10, 25, 50, 100, 200], id: \.self) { val in
                    Button {
                        withAnimation { amount = Double(val) }
                    } label: {
                        Text("$\(val)")
                            .font(.dsCaption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Int(amount) == val ? Color.chain500 : Color.surface)
                            .foregroundStyle(Int(amount) == val ? .white : .textPrimary)
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("\(val) dólares")
                }
            }

            // Live yield preview
            HStack(spacing: 0) {
                YieldPreviewChip(label: "Rendimiento\nmensual", value: "$\(String(format: "%.2f", monthlyYield)) USD")
                Divider().frame(height: 40)
                YieldPreviewChip(label: "Rendimiento\nanual", value: "$\(String(format: "%.2f", monthlyYield * 12)) USD")
                Divider().frame(height: 40)
                YieldPreviewChip(label: "Tasa\nanual", value: "\(String(format: "%.1f", project.rendimientoAnualPct))%")
            }
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 6) {
                if appState.isLoadingBalance {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Consultando tu saldo en blockchain…")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                } else if appState.balanceError != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.warning)
                    Text("No pudimos leer tu saldo on-chain. Vuelve a intentarlo.")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                } else {
                    Text("Tu saldo on-chain: $\(String(format: "%.2f", appState.walletBalanceUSDC)) USDC disponibles")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Step 2: Review
    var step2View: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Paso 2 — Revisa los detalles")
                    .font(.dsTitle)
                Text("Verifica todo antes de confirmar. Paso 3 requiere Face ID.")
                    .font(.dsCaption)
                    .foregroundStyle(.textSecondary)
            }

            // Summary
            VStack(spacing: 0) {
                SummaryRow(label: "Proyecto", value: "\(project.ciudad), \(project.estado)")
                Divider().padding(.horizontal)
                SummaryRow(label: "Monto", value: "$\(Int(amount)) USDC", accent: true)
                Divider().padding(.horizontal)
                SummaryRow(label: "Fracciones a recibir", value: "\(tokens) fracciones")
                Divider().padding(.horizontal)
                SummaryRow(label: "Rendimiento mensual est.", value: "$\(String(format: "%.2f", monthlyYield)) USD")
                Divider().padding(.horizontal)
                SummaryRow(label: "Tasa anual efectiva", value: "\(String(format: "%.1f", project.rendimientoAnualPct))%")
                Divider().padding(.horizontal)
                SummaryRow(label: "Costo de procesamiento", value: "$\(String(format: "%.2f", gasFeeUSD)) USD")
                Divider().padding(.horizontal)
                SummaryRow(label: "Total a pagar", value: "$\(String(format: "%.2f", amount + gasFeeUSD)) USDC")
            }
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Contract info — HCAI: verifiable trust
            ContractInfoView(
                address: project.contractAddress,
                network: "Base Sepolia",
                explorerURL: "https://sepolia.basescan.org"
            )

            // HCAI: no surprise fees notice
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sin costos ocultos")
                        .font(.dsCaption.weight(.semibold))
                    Text("El costo de procesamiento ($\(String(format: "%.2f", gasFeeUSD)) USD) es el único cargo adicional al monto invertido.")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
            }
            .padding(12)
            .background(Color.success.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct StepIndicator: View {
    let current: Int
    let total: Int
    var labels: [String] = []

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(1...total, id: \.self) { step in
                    Circle()
                        .fill(step <= current ? Color.chain500 : Color.gray.opacity(0.25))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Group {
                                if step < current {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(step)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(step <= current ? .white : .textSecondary)
                                }
                            }
                        )
                        .accessibilityLabel("Paso \(step) de \(total)\(step == current ? ", actual" : step < current ? ", completado" : "")")

                    if step < total {
                        Rectangle()
                            .fill(step < current ? Color.chain500 : Color.gray.opacity(0.25))
                            .frame(height: 2)
                    }
                }
            }

            if !labels.isEmpty {
                HStack(spacing: 0) {
                    ForEach(labels.indices, id: \.self) { i in
                        Text(labels[i])
                            .font(.caption2)
                            .foregroundStyle(i + 1 == current ? .chain500 : .textSecondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

struct YieldPreviewChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.dsCaption.weight(.bold))
                .foregroundStyle(.chain500)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
