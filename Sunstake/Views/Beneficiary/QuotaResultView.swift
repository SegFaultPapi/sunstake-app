import SwiftUI

struct QuotaResultView: View {
    @Environment(AppState.self) var appState
    let result: QuotaResult
    @State private var selectedTerm: PaymentTerm
    @State private var showSummary = false
    @State private var adjustedResult: QuotaResult
    @State private var showBreakdown = false
    @State private var aiExplanation: String? = nil
    @State private var isGeneratingExplanation = false

    init(result: QuotaResult) {
        self.result = result
        _selectedTerm = State(initialValue: PaymentTerm(rawValue: result.plazoMeses) ?? .thirtySix)
        _adjustedResult = State(initialValue: result)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Confidence bar — HCAI interpretability
                ConfidenceBarView(level: adjustedResult.confianza)

                // Main quota card
                VStack(spacing: 6) {
                    Text("Tu cuota mensual")
                        .font(.dsSubhead)
                        .foregroundStyle(.textSecondary)
                    Text("$\(Int(adjustedResult.cuotaMXN)) MXN/mes")
                        .font(.dsDisplay)
                        .foregroundStyle(.secondary500)
                    Text("≈ $\(String(format: "%.2f", adjustedResult.cuotaUSDC)) USDC")
                        .font(.dsFootnote)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(DSSpacing.lg)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg))

                // HCAI: 4-variable breakdown — auto-abre para transparencia, colapsable por control del usuario
                DisclosureGroup(
                    isExpanded: $showBreakdown,
                    content: { HCAIBreakdownView(result: adjustedResult).padding(.top, 8) },
                    label: {
                        Label("¿Por qué esta cuota?", systemImage: "magnifyingglass")
                            .font(.dsHeading)
                            .foregroundStyle(.textPrimary)
                    }
                )
                .padding(16)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onAppear {
                    withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                        showBreakdown = true
                    }
                }

                // HCAI: Natural language explanation — Apple Intelligence on-device
                AIExplanationCard(
                    staticFallback: adjustedResult.explicacion,
                    aiText: aiExplanation,
                    isGenerating: isGeneratingExplanation
                )
                .task(id: adjustedResult.plazoMeses) {
                    await generateExplanation(for: adjustedResult)
                }

                // HCAI: Override — user control, always visible, never blockable
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.secondary500)
                        Text("Ajusta tu propuesta")
                            .font(.dsHeading)
                        Spacer()
                        // HCAI badge
                        Text("Tú decides")
                            .font(.dsCaption2.weight(.semibold))
                            .foregroundStyle(.secondary500)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary500.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Text("Cambia el plazo y ve cómo cambia tu cuota al instante.")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)

                    HStack(spacing: 0) {
                        ForEach(PaymentTerm.allCases) { term in
                            Button {
                                UISelectionFeedbackGenerator().selectionChanged()
                                selectedTerm = term
                                recalculate(term: term)
                            } label: {
                                VStack(spacing: 2) {
                                    Text(term.label)
                                        .font(.dsCaption.weight(.semibold))
                                    if let cuota = cuotaForTerm(term) {
                                        Text("$\(Int(cuota))/mes")
                                            .font(.dsCaption2)
                                            .foregroundStyle(selectedTerm == term ? .white.opacity(0.85) : .textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTerm == term ? Color.secondary500 : Color.clear)
                                .foregroundStyle(selectedTerm == term ? .white : .textPrimary)
                            }
                            .accessibilityLabel("Plazo \(term.label)\(selectedTerm == term ? ", seleccionado" : "")")
                        }
                    }
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
                .background(Color.secondary500.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary500.opacity(0.2), lineWidth: 1))

                // Savings estimate
                HStack {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Ahorro estimado mensual")
                            .font(.dsSubhead)
                            .foregroundStyle(.textSecondary)
                        Text("$\(Int(adjustedResult.ahorroEstimadoMXN)) MXN/mes vs. CFE")
                            .font(.dsHeading)
                            .foregroundStyle(.success)
                    }
                    Spacer()
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.success)
                }
                .padding(DSSpacing.md)
                .background(Color.success.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg))

                // CTAs
                VStack(spacing: 12) {
                    Button {
                        showSummary = true
                    } label: {
                        Text("Publicar mi proyecto")
                            .font(.dsHeading)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.secondary500)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Publicar proyecto en blockchain. Requiere confirmación con Face ID.")

                    Text("Podrás revisar todos los detalles antes de confirmar con Face ID")
                        .font(.dsCaption2)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .changeRoleButton()
        .navigationTitle("Tu cuota solar")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSummary) {
            ProjectSummaryView(result: adjustedResult)
        }
    }

    private func recalculate(term: PaymentTerm) {
        adjustedResult = appState.calculateQuota(
            consumoMXN: result.consumoKWh * 3.75,
            ubicacion: result.ubicacion,
            plazo: term
        )
    }

    private func cuotaForTerm(_ term: PaymentTerm) -> Double? {
        let base = result.cuotaMXN * Double(result.plazoMeses)
        let factor = 1.0 + (36.0 / Double(term.rawValue) - 1) * 0.15
        return (base / Double(term.rawValue) * factor).rounded()
    }

    private func generateExplanation(for r: QuotaResult) async {
        guard #available(iOS 18, *) else { return }
        isGeneratingExplanation = true
        aiExplanation = nil
        let input = QuotaExplanationInput(
            cuotaMXN: r.cuotaMXN,
            consumoKWh: r.consumoKWh,
            horasSol: r.horasSol,
            tamanoPanel: r.tamanoPanel,
            coberturaPct: r.coberturaPct,
            plazoMeses: r.plazoMeses,
            ubicacion: r.ubicacion,
            rendimientoPct: r.rendimientoInversorPct,
            confianza: r.confianza.rawValue
        )
        aiExplanation = await FoundationModelsService.generateQuotaExplanation(for: input)
        isGeneratingExplanation = false
    }
}

// MARK: - AI explanation card

private struct AIExplanationCard: View {
    let staticFallback: String
    let aiText: String?
    let isGenerating: Bool

    private var displayText: String { aiText ?? staticFallback }
    private var isAIGenerated: Bool { aiText != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(.chain500)
                Text(isAIGenerated ? "Apple Intelligence" : "Explicación del cálculo")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(.chain500)
                Spacer()
                if isGenerating {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(.chain500)
                        Text("Generando…")
                            .font(.dsCaption2)
                            .foregroundStyle(.textSecondary)
                    }
                } else if isAIGenerated {
                    Label("En tu dispositivo", systemImage: "lock.shield.fill")
                        .font(.dsCaption2)
                        .foregroundStyle(.success)
                        .transition(.opacity)
                }
            }

            if isGenerating {
                ShimmerLines()
            } else if isAIGenerated, let text = aiText {
                TypewriterText(fullText: text)
                    .font(.dsBody)
                    .foregroundStyle(.textPrimary)
            } else {
                Text(staticFallback)
                    .font(.dsBody)
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // HCAI: always show data source for interpretability
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.dsCaption2)
                Text("Cálculo basado en datos reales de NASA POWER y tu consumo.")
                    .font(.dsCaption2)
            }
            .foregroundStyle(.textSecondary)
        }
        .padding(16)
        .background(Color.chain500.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isGenerating ? "Generando explicación con Apple Intelligence" : displayText)
    }
}

// MARK: - Typewriter text animation

private struct TypewriterText: View {
    let fullText: String
    // ~55 ms por carácter → ritmo pausado de escritura humana
    var charDelay: Double = 0.055

    @State private var visibleCount: Int = 0
    @State private var cursorVisible: Bool = true
    @State private var typingDone: Bool = false

    private var displayed: String { String(fullText.prefix(visibleCount)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Texto animado — el invisible reserva el alto final para evitar saltos
            ZStack(alignment: .topLeading) {
                Text(fullText)
                    .opacity(0)
                HStack(alignment: .top, spacing: 0) {
                    Text(displayed)
                    if !typingDone {
                        Text("|")
                            .opacity(cursorVisible ? 1 : 0)
                            .animation(.easeInOut(duration: 0.45).repeatForever(), value: cursorVisible)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            // Badge "Generado con Apple Intelligence" — aparece al terminar de escribir
            if typingDone {
                HStack(spacing: 5) {
                    Image(systemName: "apple.intelligence")
                        .font(.dsCaption2)
                    Text("Generado con Apple Intelligence")
                        .font(.dsCaption2.weight(.medium))
                }
                .foregroundStyle(.chain500)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear { startTyping() }
        .onChange(of: fullText) { startTyping() }
    }

    private func startTyping() {
        visibleCount = 0
        typingDone = false
        cursorVisible = true
        let total = fullText.count
        guard total > 0 else { return }

        Task {
            for i in 1...total {
                // Pequeña variación aleatoria para simular ritmo humano real
                let jitter = Double.random(in: 0.8...1.4)
                try? await Task.sleep(nanoseconds: UInt64(charDelay * jitter * 1_000_000_000))
                await MainActor.run { visibleCount = i }
            }
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) {
                    typingDone = true
                    cursorVisible = false
                }
            }
        }
    }
}

// MARK: - Loading shimmer placeholder

private struct ShimmerLines: View {
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach([0.9, 1.0, 0.75] as [CGFloat], id: \.self) { fraction in
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.3), Color.gray.opacity(0.15)],
                                startPoint: shimmer ? .trailing : .leading,
                                endPoint: shimmer ? .leading : .trailing
                            )
                        )
                        .frame(width: geo.size.width * fraction, height: 14)
                }
                .frame(height: 14)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmer = true
            }
        }
    }
}
