import SwiftUI

struct ConfidenceBarView: View {
    let level: ConfidenceLevel
    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) { expanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: expanded ? 8 : 0) {
                HStack(spacing: 8) {
                    Image(systemName: level.icon)
                        .foregroundStyle(level.color)
                        .font(.body)

                    Text("Confianza del cálculo: \(level.rawValue)")
                        .font(.dsCaption.weight(.semibold))
                        .foregroundStyle(level.color)

                    Spacer()

                    // Segmented confidence dots
                    HStack(spacing: 4) {
                        ForEach(0..<3) { i in
                            Capsule()
                                .fill(i < levelIndex ? level.color : Color.gray.opacity(0.25))
                                .frame(width: 20, height: 6)
                                .animation(.easeInOut.delay(Double(i) * 0.1), value: level)
                        }
                    }

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.dsCaption2)
                        .foregroundStyle(.textSecondary)
                }

                if expanded {
                    Text(level.detail)
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(12)
            .background(level.color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Confianza del cálculo: \(level.rawValue). \(level.detail)")
    }

    private var levelIndex: Int {
        switch level {
        case .alta: return 3
        case .media: return 2
        case .baja: return 1
        }
    }
}
