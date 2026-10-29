//
//  AppLockView.swift
//  SubCheck
//
//  Bloqueio do app com Face ID (ou a senha do aparelho). Recurso Pro:
//  sem permissão a tela nunca aparece.
//

import SwiftUI
import LocalAuthentication

struct AppLockView: View {

    /// Chamado quando a autenticação passa.
    var onUnlock: () -> Void

    @State private var isAuthenticating = false
    @State private var message: String?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(
                        Color.brandGradient,
                        in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    )
                    .softShadow()

                Text("SubCheck bloqueado")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                Button {
                    Task { await authenticate() }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if isAuthenticating {
                            ProgressView()
                        } else {
                            Image(systemName: "faceid")
                        }
                        Text("Desbloquear")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(
                        Color.brandGradient,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
                .disabled(isAuthenticating)

                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.xl)
        }
        .task { await authenticate() }
    }

    /// Biometria com queda para a senha do aparelho.
    private func authenticate() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        var error: NSError?

        // Sem biometria nem senha configurada não há como travar o app.
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            onUnlock()
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: L.t("Desbloquear suas assinaturas.")
            )
            if success {
                message = nil
                onUnlock()
            } else {
                message = L.t("Não foi possível confirmar sua identidade.")
            }
        } catch {
            message = L.t("Não foi possível confirmar sua identidade.")
        }
    }
}
