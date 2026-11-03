//
//  OnboardingView.swift
//  SubCheck
//
//  Primeira abertura: um passo a passo que ensina o app em cinco telas
//  animadas — boas-vindas (com o nome), cadastro, gastos, avisos e economia.
//  Termina com uma espera curta e a marca, para o app parecer pronto antes
//  de mostrar a tela inicial. Aparece uma vez (`onboardingDone`).
//

import SwiftUI

struct OnboardingView: View {

    static let doneKey = "onboardingDone"

    @AppStorage(OnboardingView.doneKey) private var done = false
    @AppStorage(Profile.nameKey) private var name = ""

    @State private var page = 0
    /// `true` depois de "Começar": mostra a espera e fecha.
    @State private var isPreparing = false
    @State private var progress = 0.0
    @FocusState private var editingName: Bool

    private var steps: [Step] { Step.allCases }
    private var isLast: Bool { page == steps.count - 1 }
    private var fraction: Double { Double(page + 1) / Double(steps.count) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if isPreparing {
                LoadingOverlay(title: L.t("Preparando tudo…"), progress: progress)
                    .zIndex(1)
            } else {
                content
                    .transition(.opacity)
            }
        }
        .animation(Motion.snappy, value: isPreparing)
    }

    // MARK: - Estrutura

    private var content: some View {
        VStack(spacing: Spacing.lg) {
            header
            pages
            footer
        }
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.lg)
    }

    private var header: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Spacer()
                Button {
                    editingName = false
                    finish()
                } label: {
                    Text(L.t("Pular"))
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .opacity(isLast ? 0 : 1)
                .disabled(isLast)
            }

            progressBar
        }
        .padding(.horizontal, Spacing.xl)
    }

    /// Barra que cresce a cada passo, no lugar dos pontinhos padrão.
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.hairline.opacity(0.45))
                Capsule()
                    .fill(Color.brandGradient)
                    .frame(width: max(geo.size.width * fraction, 12))
            }
        }
        .frame(height: 5)
        .animation(Motion.snappy, value: page)
    }

    private var pages: some View {
        TabView(selection: $page) {
            ForEach(steps) { step in
                pageView(step)
                    .tag(step.rawValue)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    @ViewBuilder
    private func pageView(_ step: Step) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: 0)

            illustration(for: step)

            VStack(spacing: Spacing.md) {
                Text(step.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text(step.message)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if step == .welcome { nameField }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.xl)
    }

    @ViewBuilder
    private func illustration(for step: Step) -> some View {
        switch step {
        case .welcome:  WelcomeArt()
        case .add:      AddArt()
        case .spending: SpendingArt()
        case .alerts:   AlertArt()
        case .savings:  SavingsArt()
        }
    }

    // MARK: - Nome

    private var nameField: some View {
        VStack(spacing: Spacing.sm) {
            TextField(L.t("Como podemos te chamar?"), text: $name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($editingName)
                .submitLabel(.done)
                .onSubmit { advance() }
                .padding(Spacing.md)
                .background(
                    Color.cardBackground,
                    in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(Color.hairline, lineWidth: 1)
                )
                .frame(maxWidth: 320)

            Text(L.t("Serve só para personalizar o resumo. Você pode pular."))
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Rodapé

    private var footer: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                advance()
            } label: {
                Text(isLast ? L.t("Começar") : L.t("Continuar"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(
                        Color.brandGradient,
                        in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    )
            }
            .buttonStyle(PressableStyle())

            Button {
                editingName = false
                Haptics.impact(.light)
                withAnimation(Motion.snappy) { page -= 1 }
            } label: {
                Text(L.t("Voltar"))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .opacity(page > 0 ? 1 : 0)
            .disabled(page == 0)
            .animation(Motion.snappy, value: page)
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Ações

    private func advance() {
        editingName = false
        Haptics.impact(.light)
        if isLast {
            finish()
        } else {
            withAnimation(Motion.snappy) { page += 1 }
        }
    }

    /// Fecha o onboarding: mostra a espera, avança a barra e destrava o app.
    private func finish() {
        guard !isPreparing else { return }
        editingName = false
        Haptics.success()
        withAnimation(Motion.snappy) { isPreparing = true }

        Task { @MainActor in
            for step in 1...24 {
                try? await Task.sleep(for: .milliseconds(45))
                progress = Double(step) / 24
            }
            try? await Task.sleep(for: .milliseconds(200))
            done = true
        }
    }
}

// MARK: - Passos

private enum Step: Int, CaseIterable, Identifiable {

    case welcome, add, spending, alerts, savings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome:  L.t("Bem-vindo ao SubCheck")
        case .add:      L.t("Adicione suas assinaturas")
        case .spending: L.t("Entenda seus gastos")
        case .alerts:   L.t("Nada de cobrança surpresa")
        case .savings:  L.t("Economize de verdade")
        }
    }

    var message: String {
        switch self {
        case .welcome:
            L.t("Veja todas as suas assinaturas num só lugar e descubra para onde vai o seu dinheiro.")
        case .add:
            L.t("Toque em + e escolha o serviço. O ícone, a categoria e a próxima cobrança são preenchidos para você.")
        case .spending:
            L.t("O painel mostra o total mensal, o custo por dia e o que mais pesa no seu bolso.")
        case .alerts:
            L.t("Avisamos antes de cada cobrança, na véspera do fim de um teste e na Ilha Dinâmica.")
        case .savings:
            L.t("Insights, previsão de 12 meses e o simulador de cancelamento mostram onde cortar.")
        }
    }
}

// MARK: - Ilustrações

/// Marca com anéis que respiram.
private struct WelcomeArt: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.brand.opacity(0.16), lineWidth: 2)
                    .frame(
                        width: 156 + CGFloat(index) * 44,
                        height: 156 + CGFloat(index) * 44
                    )
                    .scaleEffect(pulse ? 1.05 : 0.94)
                    .opacity(pulse ? 0.35 : 0.9)
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 2.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.25),
                        value: pulse
                    )
            }

            BrandMark(size: 132)
        }
        .frame(height: 240)
        .onAppear { pulse = true }
    }
}

/// Linhas de assinatura entrando na lista, com o botão + flutuando.
private struct AddArt: View {

    @State private var shown = false

    private let rows: [(icon: String, tint: Color, width: CGFloat, price: String)] = [
        ("play.tv.fill", .danger, 96, "R$ 39,90"),
        ("music.note", .success, 74, "R$ 21,90"),
        ("icloud.fill", .info, 88, "R$ 12,90")
    ]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: Spacing.md) {
                    Image(systemName: row.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(
                            row.tint.gradient,
                            in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.textPrimary.opacity(0.7))
                            .frame(width: row.width, height: 9)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.textTertiary.opacity(0.45))
                            .frame(width: row.width * 0.55, height: 7)
                    }

                    Spacer(minLength: 0)

                    Text(row.price)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                }
                .cardSurface(padding: Spacing.md)
                .opacity(shown ? 1 : 0)
                .offset(x: shown ? 0 : 70)
                .animation(Motion.snappy.delay(Double(index) * 0.12), value: shown)
            }
        }
        .frame(maxWidth: 340)
        .overlay(alignment: .bottomTrailing) { plusButton }
        .onAppear { shown = true }
    }

    private var plusButton: some View {
        Image(systemName: "plus")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 54, height: 54)
            .background(Color.brandGradient, in: Circle())
            .softShadow()
            .offset(x: 10, y: 12)
    }
}

/// Rosca que se preenche e três números de exemplo.
private struct SpendingArt: View {

    @State private var fill = 0.0

    var body: some View {
        HStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(Color.brand.opacity(0.14), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: fill)
                    .stroke(Color.brandGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("R$ 1.240")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(L.t("por mês"))
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(width: 128, height: 128)

            VStack(spacing: Spacing.sm) {
                kpi(L.t("Custo anual"), "R$ 14.880", .info)
                kpi(L.t("Custo por dia"), "R$ 40,76", .warning)
                kpi(L.t("Maior assinatura"), "Streaming", .danger)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) { fill = 0.68 }
        }
    }

    private func kpi(_ title: String, _ value: String, _ tint: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer(minLength: 0)
        }
        .cardSurface(padding: Spacing.sm)
    }
}

/// Uma miniatura da Ilha Dinâmica com contagem regressiva ao vivo.
private struct AlertArt: View {

    @State private var start = Date()
    @State private var ring = false

    private var target: Date { start.addingTimeInterval(5 * 3600 + 42 * 60) }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.warning.gradient, in: Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(L.t("Cobrança próxima"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Streaming")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer(minLength: Spacing.sm)

                Text(timerInterval: start...target, countsDown: true)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.black, in: Capsule())
            .softShadow()
            .frame(maxWidth: 340)

            HStack(spacing: Spacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            (index == 0 ? Color.success : Color.brand.opacity(0.25)).gradient,
                            in: Circle()
                        )
                        .scaleEffect(ring && index == 0 ? 1.12 : 1)
                        .animation(
                            .easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(Double(index) * 0.2),
                            value: ring
                        )
                }
            }
        }
        .onAppear { ring = true }
    }
}

/// Anel de meta batida, resumindo o lado "economize".
private struct SavingsArt: View {

    @State private var fill = 0.0

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(Color.success.opacity(0.16), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: fill)
                    .stroke(Color.successGradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("R$ 78")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text(L.t("por mês"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(width: 156, height: 156)

            Label(L.t("Meta batida. Parabéns!"), systemImage: "leaf.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.success)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.15)) { fill = 0.8 }
        }
    }
}

#Preview { OnboardingView() }
