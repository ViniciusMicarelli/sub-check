//
//  OnboardingView.swift
//  SubCheck
//
//  Primeira abertura: um passo a passo que ensina o app em sete telas
//  animadas — boas-vindas (com o nome), cadastro, gastos, avisos, economia,
//  o teste grátis do Pro e a pergunta do iCloud.
//  Termina com uma espera curta e a marca, para o app parecer pronto antes
//  de mostrar a tela inicial. Aparece uma vez (`onboardingDone`).
//

import SwiftUI
import SwiftData

struct OnboardingView: View {

    static let doneKey = "onboardingDone"

    @AppStorage(OnboardingView.doneKey) private var done = false
    @AppStorage(Profile.nameKey) private var name = ""
    @AppStorage(L.languageKey) private var language: AppLanguage = .system
    @AppStorage("appearance") private var appearance: AppearanceOption = .system
    @AppStorage(SharedModelContainer.iCloudSyncKey) private var iCloudSync = false
    @Query private var subscriptions: [Subscription]
    @State private var showAdd = false
    /// `true` depois que o usuário respondeu à pergunta do iCloud.
    @State private var syncAnswered = false
    @State private var showTour = false
    private var store = StoreService.shared

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
        .preferredColorScheme(appearance.colorScheme)
        .environment(\.locale, language.locale ?? Locale.current)
        .onChange(of: language) { _, newValue in L.store(newValue) }
        .sheet(isPresented: $showAdd) { AddSubscriptionView() }
        .sheet(isPresented: $showTour) { ProTourView() }
        #if DEBUG
        // `-onboardingStartPage 5` ao lançar pula direto para uma página.
        .onAppear {
            let start = UserDefaults.standard.integer(forKey: "onboardingStartPage")
            if (1..<steps.count).contains(start) { page = start }
        }
        #endif
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
                .accessibilityHidden(true)

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

            if step == .welcome {
                nameField
                preferences
            }
            if step == .add { addNowButton }
            if step == .pro { proOffer }
            if step == .sync { syncChoice }

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
        case .pro:      TrialArt(days: StoreService.trialDays)
        case .sync:     SyncArt()
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

    // MARK: - Idioma e tema

    private var preferences: some View {
        VStack(spacing: Spacing.sm) {
            Picker(L.t("Idioma"), selection: $language) {
                ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker(L.t("Tema"), selection: $appearance) {
                ForEach(AppearanceOption.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: 320)
    }

    // MARK: - Primeira assinatura

    @ViewBuilder
    private var addNowButton: some View {
        Button {
            Haptics.impact(.light)
            showAdd = true
        } label: {
            Label(
                subscriptions.isEmpty ? L.t("Adicionar agora") : L.t("Adicionar outra"),
                systemImage: subscriptions.isEmpty ? "plus.circle.fill" : "plus"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.brand)
        }
        .buttonStyle(PressableStyle())

        if !subscriptions.isEmpty {
            Label(L.t("Assinatura adicionada!"), systemImage: "checkmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.success)
                .transition(.opacity)
        }
    }

    // MARK: - Teste grátis e Pro

    /// O que o teste libera, em linhas curtas. Termina deixando claro que
    /// nada é cobrado e que o app continua grátis depois.
    private var proOffer: some View {
        VStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                perk(L.t("Assinaturas ilimitadas"))
                perk(LiveSurface.text(island: "Ilha Dinâmica e iCloud", noIsland: "Atividade ao Vivo e iCloud"))
                perk(L.t("Relatório em PDF, exportação e Face ID"))
                perk(L.t("Análise, previsão e simulador de cancelamento"))
            }
            .frame(maxWidth: 320, alignment: .leading)

            Button {
                Haptics.impact(.light)
                showTour = true
            } label: {
                Label(L.t("Ver o que muda no Pro"), systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brand)
            }
            .buttonStyle(PressableStyle())

            Text(afterTrialText)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320)
        }
    }

    private func perk(_ text: String) -> some View {
        Label {
            Text(text)
                .font(.footnote)
                .foregroundStyle(Color.textPrimary)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.success)
        }
    }

    /// Deixa explícito que testar não custa nada e o que acontece depois.
    private var afterTrialText: String {
        var text = L.t(
            "O teste só começa quando você ativar, sem cartão e sem cobrança. Depois dos %lld dias, o app continua grátis com até %lld assinaturas e %lld contas.",
            StoreService.trialDays, StoreService.freeLimit, StoreService.freeBillLimit
        )
        if let price = store.displayPrice {
            text += " " + L.t("Para manter o Pro: %@, uma única vez.", price)
        }
        return text
    }

    // MARK: - iCloud

    /// `true` quando há uma conta do iCloud entrada neste aparelho.
    private var hasICloudAccount: Bool { FileManager.default.ubiquityIdentityToken != nil }

    /// A pergunta é explícita: quem não responder fica só neste aparelho
    /// (o padrão seguro) e pode ligar depois em Ajustes.
    private var syncChoice: some View {
        VStack(spacing: Spacing.sm) {
            syncOption(
                title: L.t("Sincronizar com iCloud"),
                detail: L.t("Iguais em todos os seus aparelhos"),
                symbol: "icloud.fill",
                selected: syncAnswered && iCloudSync,
                enabled: store.hasProAccess
            ) { choose(sync: true) }

            syncOption(
                title: L.t("Só neste aparelho"),
                detail: L.t("Nada sai do seu iPhone"),
                symbol: "iphone",
                selected: syncAnswered && !iCloudSync,
                enabled: true
            ) { choose(sync: false) }

            Group {
                if !store.hasProAccess {
                    Text(L.t("A sincronização com iCloud faz parte do SubCheck Pro."))
                } else if syncAnswered && iCloudSync && !hasICloudAccount {
                    Text(L.t("Entre no iCloud em Ajustes do iOS para sincronizar."))
                        .foregroundStyle(Color.warning)
                } else if syncAnswered && iCloudSync {
                    Text(L.t("Passa a valer na próxima vez que você abrir o SubCheck."))
                } else {
                    Text(L.t("Você pode mudar isso depois em Ajustes."))
                }
            }
            .font(.caption2)
            .foregroundStyle(Color.textTertiary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 320)
    }

    private func syncOption(
        title: String, detail: String, symbol: String,
        selected: Bool, enabled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(selected ? Color.brand : Color.textSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.brand : Color.textTertiary)
            }
            .padding(Spacing.md)
            .background(
                Color.cardBackground,
                in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(selected ? Color.brand : Color.hairline, lineWidth: selected ? 2 : 1)
            )
            .opacity(enabled ? 1 : 0.5)
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func choose(sync: Bool) {
        Haptics.impact(.light)
        iCloudSync = sync
        withAnimation(Motion.snappy) { syncAnswered = true }
    }

    // MARK: - Rodapé

    private var footer: some View {
        VStack(spacing: Spacing.sm) {
            if steps[page] == .pro && store.canStartTrial {
                proChoice
            } else {
                primaryButton(isLast ? L.t("Começar") : L.t("Continuar")) { advance() }
            }

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

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
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
    }

    /// O Pro não liga sozinho: a pessoa escolhe testar ou seguir no grátis.
    private var proChoice: some View {
        VStack(spacing: Spacing.sm) {
            primaryButton(L.t("Ativar 7 dias grátis")) {
                store.startTrial()
                Haptics.success()
                advance()
            }

            Button {
                advance()
            } label: {
                Text(L.t("Continuar no grátis"))
                    .font(.headline)
                    .foregroundStyle(Color.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(
                        Color.brand.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    )
            }
            .buttonStyle(PressableStyle())
        }
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

    case welcome, add, spending, alerts, savings, pro, sync

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome:  L.t("Bem-vindo ao SubCheck")
        case .add:      L.t("Adicione suas assinaturas")
        case .spending: L.t("Entenda seus gastos")
        case .alerts:   L.t("Nada de cobrança surpresa")
        case .savings:  L.t("Economize de verdade")
        case .pro:      L.t("onboarding.pro.title", StoreService.trialDays)
        case .sync:     L.t("Seus dados, onde você estiver")
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
            LiveSurface.text(island: "Avisamos antes de cada cobrança, na véspera do fim de um teste e na Ilha Dinâmica.", noIsland: "Avisamos antes de cada cobrança, na véspera do fim de um teste e na tela de bloqueio.")
        case .savings:
            L.t("Insights, previsão de 12 meses e o simulador de cancelamento mostram onde cortar.")
        case .pro:
            L.t("Teste tudo do SubCheck Pro de graça por %lld dias. Ou continue no grátis e ative quando quiser.", StoreService.trialDays)
        case .sync:
            L.t("Com o iCloud, suas assinaturas e contas ficam iguais em todos os seus aparelhos. Quer ligar a sincronização?")
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

/// Selo grande com os dias de teste.
private struct TrialArt: View {

    let days: Int
    @State private var shine = false

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.brandGradient)
                    .frame(width: 104, height: 104)
                    .shadow(color: Color.brand.opacity(0.35), radius: shine ? 18 : 8)
                VStack(spacing: -2) {
                    Text("\(days)")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                    Text(L.t("dias"))
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                }
                .foregroundStyle(.white)
            }

            Text(L.t("TESTE GRÁTIS"))
                .font(.caption.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(Color.success)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 4)
                .background(Color.success.opacity(0.14), in: Capsule())
        }
        .frame(height: 156)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { shine = true }
        }
    }
}

/// Dois aparelhos ligados por uma nuvem.
private struct SyncArt: View {

    @State private var pulse = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "icloud.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.brandGradient)
                .scaleEffect(pulse ? 1.06 : 0.96)

            HStack(spacing: Spacing.lg) {
                Image(systemName: "iphone")
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
                    .foregroundStyle(Color.textTertiary)
                Image(systemName: "ipad")
            }
            .font(.system(size: 34))
            .foregroundStyle(Color.textSecondary)
        }
        .frame(height: 156)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

#Preview { OnboardingView() }
