import SwiftUI

/// Dashboard que muestra el estado de financiamiento del proyecto publicado
/// por el beneficiario. Los inversores van comprando fracciones hasta llegar
/// al 100%, momento en que el beneficiario puede iniciar sus pagos mensuales.
struct BeneficiaryFinancingView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        NavigationStack {
            Group {
                if appState.activeProjects.isEmpty {
                    FinancingEmptyState()
                } else if appState.activeProjects.count == 1, let project = appState.activeProjects.first {
                    FinancingDashboardContent(project: project)
                } else {
                    MultiProjectFinancingView(projects: appState.activeProjects)
                }
            }
            .navigationTitle("Mi proyecto")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Multi-project compact list

private struct MultiProjectFinancingView: View {
    let projects: [SolarProject]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(projects.count) paneles activos")
                            .font(.dsHeading)
                        Spacer()
                        Label("Máx. 3 paneles", systemImage: "info.circle")
                            .font(.dsCaption2)
                            .foregroundStyle(.textSecondary)
                    }
                    Text("Toca un panel para ver su estado de financiamiento. Añade paneles desde la pestaña \"Mi Panel\".")
                        .font(.dsCaption2)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ForEach(Array(projects.enumerated()), id: \.element.id) { idx, project in
                    NavigationLink(destination: FinancingDashboardContent(project: project)) {
                        CompactProjectCard(index: idx + 1, project: project)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 24)
        }
    }
}

private struct CompactProjectCard: View {
    let index: Int
    let project: SolarProject

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Index badge
                ZStack {
                    Circle()
                        .fill(Color.secondary500.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Text("\(index)")
                        .font(.dsHeading)
                        .foregroundStyle(.secondary500)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Panel \(index)")
                            .font(.dsCaption.weight(.semibold))
                        FundingStatusBadge(status: project.status)
                    }
                    Text("\(project.ciudad), \(project.estado)")
                        .font(.dsCaption2)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(Int(project.porcentajeFinanciado * 100))%")
                        .font(.dsCaption.weight(.bold))
                        .foregroundStyle(.chain500)
                    Text("financiado")
                        .font(.dsCaption2)
                        .foregroundStyle(.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.textSecondary)
            }
            .padding(16)

            // Mini funding bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.chain500)
                        .frame(width: geo.size.width * project.porcentajeFinanciado, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
        .accessibilityLabel("Panel \(index) en \(project.ciudad), \(project.estado). \(Int(project.porcentajeFinanciado * 100))% financiado.")
    }
}

// MARK: - Dashboard con proyecto activo

struct FinancingDashboardContent: View {
    let project: SolarProject

    // Aun no tenemos un indexer onchain que liste compradores por contrato,
    // asi que partimos vacio y mostramos un empty state honesto en lugar
    // de inversores ficticios. La barra de progreso si refleja el porcentaje real
    // del proyecto.
    private let investors: [(label: String, monto: Double, pct: Double)] = []

    private var montoRecaudado: Double {
        project.montoTotalUSD * project.porcentajeFinanciado
    }
    private var montoFaltante: Double {
        project.montoTotalUSD * (1 - project.porcentajeFinanciado)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Anillo de financiamiento ──────────────────────────────
                FundingRingCard(
                    porcentaje: project.porcentajeFinanciado,
                    ciudad: project.ciudad,
                    estado: project.estado,
                    status: project.status
                )

                // ── Métricas clave ────────────────────────────────────────
                HStack(spacing: 0) {
                    FinancingMetric(
                        icon: "dollarsign.circle.fill",
                        iconColor: .chain500,
                        value: "$\(Int(montoRecaudado))",
                        label: "recaudados USD"
                    )
                    Divider().frame(height: 36)
                    FinancingMetric(
                        icon: "person.2.fill",
                        iconColor: .secondary500,
                        value: investors.isEmpty ? "—" : "\(investors.count)",
                        label: "inversores"
                    )
                    Divider().frame(height: 36)
                    FinancingMetric(
                        icon: "calendar",
                        iconColor: .textSecondary,
                        value: project.status == .open ? "Abierto" : "Cerrado",
                        label: "estado"
                    )
                }
                .padding(.vertical, 14)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // ── Barra de progreso detallada ───────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Financiamiento recaudado")
                            .font(.dsSubhead)
                        Spacer()
                        Text("$\(Int(montoRecaudado)) / $\(Int(project.montoTotalUSD)) USD")
                            .font(.dsCaption.weight(.semibold))
                            .foregroundStyle(.textSecondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        colors: [.chain500, .chain500.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geo.size.width * project.porcentajeFinanciado,
                                    height: 10
                                )
                                .animation(.easeOut(duration: 0.9), value: project.porcentajeFinanciado)
                        }
                    }
                    .frame(height: 10)

                    if project.status == .open {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.dsCaption2)
                                .foregroundStyle(.textSecondary)
                            Text("Faltan $\(Int(montoFaltante)) USD para financiar tu panel completo.")
                                .font(.dsCaption2)
                                .foregroundStyle(.textSecondary)
                        }
                    } else {
                        Label("Tu proyecto está 100% financiado", systemImage: "checkmark.circle.fill")
                            .font(.dsCaption.weight(.semibold))
                            .foregroundStyle(.success)
                    }
                }
                .padding(16)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // ── Lista de inversores (anónima) ─────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("Inversores en tu proyecto")
                        .font(.dsHeading)

                    if investors.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "clock")
                                .foregroundStyle(.textSecondary)
                            Text("Aún no hay inversores registrados. Los proyectos suelen financiarse en 7–14 días.")
                                .font(.dsCaption)
                                .foregroundStyle(.textSecondary)
                        }
                        .padding(14)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(investors.enumerated()), id: \.offset) { index, investor in
                                InvestorRow(
                                    label: investor.label,
                                    monto: investor.monto,
                                    pct: investor.pct
                                )
                                if index < investors.count - 1 {
                                    Divider().padding(.leading, 42)
                                }
                            }
                        }
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                // ── Detalles del panel ────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Label("Detalles de tu panel", systemImage: "sun.max.fill")
                        .font(.dsHeading)
                        .foregroundStyle(.secondary500)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        PanelDetailTile(
                            icon: "bolt.fill",
                            label: "Capacidad",
                            value: "2 kW"
                        )
                        PanelDetailTile(
                            icon: "leaf.fill",
                            label: "CO₂ evitado",
                            value: "1.2 ton/año"
                        )
                        PanelDetailTile(
                            icon: "chart.line.uptrend.xyaxis",
                            label: "Rendimiento inversor",
                            value: "\(String(format: "%.1f", project.rendimientoAnualPct))% anual"
                        )
                        PanelDetailTile(
                            icon: "calendar",
                            label: "Plazo de pago",
                            value: "\(project.plazoTotalMeses) meses"
                        )
                    }
                }

                // ── Contrato verificable ─ HCAI ───────────────────────────
                ContractInfoView(
                    address: project.contractAddress,
                    network: "Base Sepolia",
                    explorerURL: "https://sepolia.basescan.org"
                )

                // ── CTA si está 100% financiado ───────────────────────────
                if project.status == .funded {
                    VStack(spacing: 8) {
                        Label("¡Proyecto financiado!", systemImage: "checkmark.seal.fill")
                            .font(.dsHeading)
                            .foregroundStyle(.success)
                        Text("Tu panel está listo para instalarse. Podrás empezar a pagar tus cuotas desde la pestaña Mi Panel.")
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.success.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
        .refreshable { }
    }
}

// MARK: - Estado vacío (sin proyecto publicado)

struct FinancingEmptyState: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.secondary500.opacity(0.08))
                        .frame(width: 110, height: 110)
                    Image(systemName: "sun.max.circle")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.secondary500, .primary500],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 8) {
                    Text("Aún no tienes un proyecto")
                        .font(.dsTitle)
                        .multilineTextAlignment(.center)
                    Text("Calcula tu cuota solar y publícala para que inversores financien tu panel.")
                        .font(.dsBody)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }

            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "1.circle.fill")
                        .foregroundStyle(.secondary500)
                    Text("Ingresa tu consumo eléctrico y ubicación")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "2.circle.fill")
                        .foregroundStyle(.secondary500)
                    Text("La IA calcula tu cuota ideal con desglose visible")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "3.circle.fill")
                        .foregroundStyle(.secondary500)
                    Text("Publicas tu proyecto y los inversores lo financian")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Spacer()

            VStack(spacing: 8) {
                Text("Ve a la pestaña \"Mi Panel\" para calcular tu cuota y publicar tu proyecto.")
                    .font(.dsCaption)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - Subcomponentes

private struct FundingRingCard: View {
    let porcentaje: Double
    let ciudad: String
    let estado: String
    let status: ProjectStatus

    @State private var animated: Double = 0

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "house.fill")
                            .font(.dsCaption2)
                            .foregroundStyle(.secondary500)
                        Text("\(ciudad), \(estado)")
                            .font(.dsSubhead.weight(.semibold))
                    }
                    Text("Proyecto solar publicado")
                        .font(.dsCaption2)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                FundingStatusBadge(status: status)
            }

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.12), lineWidth: 18)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: animated)
                    .stroke(
                        AngularGradient(
                            colors: [.chain500, .chain500.opacity(0.45)],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 160, height: 160)
                    .animation(.easeOut(duration: 1.1), value: animated)

                VStack(spacing: 2) {
                    Text("\(Int(porcentaje * 100))%")
                        .font(.dsNumber)
                        .foregroundStyle(.textPrimary)
                        .contentTransition(.numericText())
                    Text("financiado")
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                }
            }
            .accessibilityLabel(
                "Proyecto \(Int(porcentaje * 100))% financiado por inversores."
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear { animated = porcentaje }
    }
}

struct FundingStatusBadge: View {
    let status: ProjectStatus

    var body: some View {
        switch status {
        case .open:
            Label("Buscando inversores", systemImage: "circle.fill")
                .font(.dsCaption2.weight(.semibold))
                .foregroundStyle(.secondary500)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary500.opacity(0.1))
                .clipShape(Capsule())
        case .funded:
            Label("Financiado", systemImage: "checkmark.circle.fill")
                .font(.dsCaption2.weight(.semibold))
                .foregroundStyle(.success)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.success.opacity(0.1))
                .clipShape(Capsule())
        case .completed:
            Label("Completado", systemImage: "checkmark.seal.fill")
                .font(.dsCaption2.weight(.semibold))
                .foregroundStyle(.chain500)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.chain500.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

private struct FinancingMetric: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.dsCaption.weight(.bold))
                .foregroundStyle(.textPrimary)
            Text(label)
                .font(.dsCaption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct InvestorRow: View {
    let label: String
    let monto: Double
    let pct: Double

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.chain500.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.chain500)
            }
            Text(label)
                .font(.dsCaption.weight(.medium))
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("$\(Int(monto)) USDC")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(.textPrimary)
                Text("\(String(format: "%.1f", pct))% del proyecto")
                    .font(.dsCaption2)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .accessibilityLabel("\(label), $\(Int(monto)) USDC, \(String(format: "%.1f", pct))% del proyecto")
    }
}

private struct PanelDetailTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary500)
            Text(value)
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(.textPrimary)
            Text(label)
                .font(.dsCaption2)
                .foregroundStyle(.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
