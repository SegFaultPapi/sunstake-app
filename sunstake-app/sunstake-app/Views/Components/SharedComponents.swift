import SwiftUI

// MARK: - Biometric confirmation sheet

struct BiometricConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let subtitle: String
    let onConfirm: () -> Void

    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 28) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.sunOrange.opacity(0.1))
                        .frame(width: 90, height: 90)
                    Image(systemName: "faceid")
                        .font(.system(size: 44))
                        .foregroundStyle(.sunOrange)
                }
                VStack(spacing: 6) {
                    Text(title)
                        .font(.sunTitle)
                    Text(subtitle)
                        .font(.sunCaption)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }

            // HCAI: responsible design — explicit biometric notice
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("Tu Face ID confirma esta operación. Ninguna transacción se realiza sin tu aprobación explícita.")
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
            .padding(12)
            .background(Color.green.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    isAuthenticating = true
                    // Simulate Face ID auth (real: use LocalAuthentication)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isAuthenticating = false
                        onConfirm()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isAuthenticating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "faceid")
                        }
                        Text(isAuthenticating ? "Autenticando..." : "Confirmar con Face ID")
                            .font(.sunHeading)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.sunOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isAuthenticating)

                Button {
                    dismiss()
                } label: {
                    Text("Cancelar")
                        .font(.sunCaption.weight(.medium))
                        .foregroundStyle(.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Contract info — HCAI verifiable trust

struct ContractInfoView: View {
    let address: String
    let network: String
    let explorerURL: String

    @State private var copied = false

    private var shortAddress: String {
        "\(address.prefix(8))...\(address.suffix(6))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Contrato verificable", systemImage: "link.circle.fill")
                .font(.sunCaption.weight(.semibold))
                .foregroundStyle(.chainIndigo)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shortAddress)
                        .font(.caption.monospaced())
                        .foregroundStyle(.chainIndigo)
                    Text("Red: \(network)")
                        .font(.caption2)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        UIPasteboard.general.string = address
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(.chainIndigo)
                    }
                    .accessibilityLabel(copied ? "Copiado" : "Copiar dirección del contrato")

                    Button {
                        if let url = URL(string: "\(explorerURL)/address/\(address)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Basescan", systemImage: "arrow.up.right.square")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.chainIndigo)
                    }
                    .accessibilityLabel("Ver contrato en Basescan")
                }
            }
        }
        .padding(14)
        .background(Color.chainIndigo.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.chainIndigo.opacity(0.15), lineWidth: 1))
    }
}
