import SwiftUI

struct TransactionLoaderView<Destination: View>: View {
    @Environment(AppState.self) var appState
    let successTitle: String
    let successSubtitle: String
    let destination: () -> Destination

    @State private var navigateAway = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            switch appState.transactionState {
            case .idle:
                EmptyView()

            case .creatingContract, .mintingTokens, .confirming, .processing:
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.chain500.opacity(0.15), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.chain500)
                    }
                    Text(appState.transactionState.label)
                        .font(.dsHeading)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: appState.transactionState.label)

                    // HCAI: visible progress steps
                    VStack(spacing: 8) {
                        LoaderStep(label: "Creando contrato", isDone: isDone(.creatingContract), isCurrent: isCurrent(.creatingContract))
                        LoaderStep(label: "Emitiendo participaciones", isDone: isDone(.mintingTokens), isCurrent: isCurrent(.mintingTokens))
                        LoaderStep(label: "Confirmando en red de pagos", isDone: isDone(.confirming), isCurrent: isCurrent(.confirming))
                    }
                    .padding(16)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            case .success(let hash), .purchaseSuccess(let hash):
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.success.opacity(0.12))
                            .frame(width: 100, height: 100)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.success)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .transition(.scale)

                    VStack(spacing: 8) {
                        Text(successTitle)
                            .font(.dsTitle)
                        Text(successSubtitle)
                            .font(.dsCaption)
                            .foregroundStyle(.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // HCAI: verifiable tx hash always shown
                    VStack(spacing: 8) {
                        Text("Código de verificación")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.textSecondary)
                        HStack(spacing: 6) {
                            Text("\(hash.prefix(8))...\(hash.suffix(6))")
                                .font(.caption.monospaced())
                                .foregroundStyle(.chain500)
                            Button {
                                UIPasteboard.general.string = hash
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.chain500)
                            }
                            .accessibilityLabel("Copiar código de verificación")
                        }
                        Button {
                            if let url = URL(string: "https://sepolia.basescan.org/tx/\(hash)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Ver comprobante", systemImage: "arrow.up.right.square")
                                .font(.dsCaption.weight(.semibold))
                                .foregroundStyle(.chain500)
                        }
                        .accessibilityLabel("Ver comprobante de la transacción")
                    }
                    .padding(16)
                    .background(Color.chain500.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        appState.resetTransaction()
                        navigateAway = true
                    } label: {
                        Text("Continuar")
                            .font(.dsHeading)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.secondary500)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .transition(.scale.combined(with: .opacity))

            case .error(let message):
                VStack(spacing: 16) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.danger)
                    Text("Error en la transacción")
                        .font(.dsTitle)
                    Text(message)
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        appState.resetTransaction()
                    } label: {
                        Text("Reintentar")
                            .font(.dsHeading)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.secondary500)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }

            Spacer()
        }
        .padding(24)
        .animation(.spring(response: 0.4), value: appState.transactionState.isSuccess)
        .navigationDestination(isPresented: $navigateAway) {
            destination()
        }
        .navigationBarBackButtonHidden(appState.transactionState.isLoading)
    }

    private func isDone(_ state: TransactionState) -> Bool {
        switch (state, appState.transactionState) {
        case (.creatingContract, .mintingTokens), (.creatingContract, .confirming),
             (.mintingTokens, .confirming): return true
        default: return appState.transactionState.isSuccess
        }
    }

    private func isCurrent(_ state: TransactionState) -> Bool {
        state == appState.transactionState
    }
}

struct LoaderStep: View {
    let label: String
    let isDone: Bool
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isDone ? Color.success : isCurrent ? Color.chain500 : Color.gray.opacity(0.2))
                    .frame(width: 20, height: 20)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                } else if isCurrent {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                }
            }
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(isCurrent ? .textPrimary : isDone ? .success : .textSecondary)
            Spacer()
        }
        .accessibilityLabel("\(label): \(isDone ? "completado" : isCurrent ? "en progreso" : "pendiente")")
    }
}
