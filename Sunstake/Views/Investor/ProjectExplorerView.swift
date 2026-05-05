import SwiftUI

struct ProjectExplorerView: View {
    @Environment(AppState.self) var appState
    @State private var searchText = ""
    @State private var selectedState: String? = nil
    @State private var minYield: Double = 0
    @State private var showFilters = false

    private let states = ["JAL", "NL", "YUC", "QRO"]

    var filteredProjects: [SolarProject] {
        appState.projects.filter { project in
            let matchesState = selectedState == nil || project.estado == selectedState
            let matchesYield = project.rendimientoAnualPct >= minYield
            let matchesSearch = searchText.isEmpty ||
                project.ciudad.localizedCaseInsensitiveContains(searchText) ||
                project.estado.localizedCaseInsensitiveContains(searchText)
            return matchesState && matchesYield && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "Todos", isSelected: selectedState == nil) {
                            selectedState = nil
                        }
                        ForEach(states, id: \.self) { state in
                            FilterChip(label: state, isSelected: selectedState == state) {
                                selectedState = selectedState == state ? nil : state
                            }
                        }
                        Divider().frame(height: 20)
                        FilterChip(
                            label: "Rendimiento ≥ \(Int(minYield))%",
                            isSelected: minYield > 0,
                            icon: "arrow.up.circle"
                        ) {
                            minYield = minYield > 0 ? 0 : 9.0
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.white)

                Divider()

                // Project list
                if filteredProjects.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 52))
                            .foregroundStyle(.textSecondary)
                        VStack(spacing: 8) {
                            Text("Sin proyectos con esos filtros")
                                .font(.dsHeading)
                            Text("Prueba quitando algún filtro o buscando otra ciudad.")
                                .font(.dsCaption)
                                .foregroundStyle(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        Button("Quitar filtros") {
                            selectedState = nil
                            minYield = 0
                            searchText = ""
                        }
                        .font(.dsCaption.weight(.semibold))
                        .foregroundStyle(.chain500)
                        .accessibilityLabel("Quitar todos los filtros y ver todos los proyectos")
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Impact summary
                            HStack(spacing: 16) {
                                MiniImpactStat(
                                    icon: "leaf.fill",
                                    value: "\(String(format: "%.1f", filteredProjects.reduce(0) { $0 + $1.co2ToneladasAnio })) ton",
                                    label: "CO₂/año"
                                )
                                MiniImpactStat(
                                    icon: "bolt.fill",
                                    value: "\(filteredProjects.reduce(0) { $0 + $1.kwhGeneradosAnio } / 1000)k kWh",
                                    label: "generados/año"
                                )
                                MiniImpactStat(
                                    icon: "house.fill",
                                    value: "\(filteredProjects.filter(\.isOpen).count)",
                                    label: "proyectos abiertos"
                                )
                            }
                            .padding(14)
                            .background(Color.success.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            ForEach(filteredProjects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCardView(project: project)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .changeRoleButton()
            .navigationTitle("Proyectos")
            .searchable(text: $searchText, prompt: "Ciudad o estado")
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.dsCaption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.chain500 : Color.surface)
            .foregroundStyle(isSelected ? .white : .textPrimary)
            .clipShape(Capsule())
        }
        .accessibilityLabel("\(label)\(isSelected ? ", seleccionado" : "")")
    }
}

struct MiniImpactStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.success)
            Text(value)
                .font(.dsCaption.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
