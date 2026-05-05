import SwiftUI

struct OwnershipRingView: View {
    let percentage: Double
    let mesesPagados: Int
    let plazoTotal: Int

    @State private var animatedPct: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 20)
                    .frame(width: 180, height: 180)

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedPct)
                    .stroke(
                        AngularGradient(
                            colors: [Color.primary500, Color.secondary500],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 180, height: 180)
                    .animation(.easeOut(duration: 1.2), value: animatedPct)

                // Center content
                VStack(spacing: DSSpacing.xs) {
                    Text("\(Int(percentage * 100))%")
                        .font(.dsNumber)
                        .foregroundStyle(.textPrimary)
                        .contentTransition(.numericText())
                    Text("tuyo")
                        .font(.dsFootnote)
                        .foregroundStyle(.textSecondary)
                }
            }
            .accessibilityLabel("Propiedad del panel: \(Int(percentage * 100))%. \(mesesPagados) de \(plazoTotal) meses pagados.")

            Text("\(mesesPagados) de \(plazoTotal) meses pagados")
                .font(.dsFootnote)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            animatedPct = percentage
        }
        .onChange(of: percentage) { _, new in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedPct = new
            }
        }
    }
}
