//
//  Motion.swift
//  SubCheck
//
//  Linguagem de movimento do app: molas curtas e amortecidas, entrada em
//  cascata e resposta ao toque. Tudo respeita "Reduzir Movimento".
//

import SwiftUI

enum Motion {
    /// Mola padrão: rápida, sem sobra visível.
    static let snappy = Animation.spring(response: 0.35, dampingFraction: 0.82)
    /// Mola com um pouco de balanço, para confirmações e seleção.
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.62)
    /// Atraso entre elementos de uma cascata de entrada.
    static let stagger = 0.06
}

// MARK: - Toque

/// Afunda levemente ao pressionar e volta com mola.
struct PressableStyle: ButtonStyle {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

// MARK: - Entrada

/// Sobe e aparece na primeira exibição, com atraso proporcional ao índice.
private struct StaggeredAppear: ViewModifier {

    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 18)
            .onAppear {
                guard !shown else { return }
                withAnimation(Motion.snappy.delay(Double(index) * Motion.stagger)) {
                    shown = true
                }
            }
    }
}

/// Suaviza a entrada e a saída de blocos conforme rolam pela tela.
private struct RevealOnScroll: ViewModifier {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.scrollTransition(.animated(Motion.snappy)) { view, phase in
                view
                    .opacity(phase.isIdentity ? 1 : 0.35)
                    .scaleEffect(phase.isIdentity ? 1 : 0.95)
            }
        }
    }
}

extension View {
    func staggeredAppear(_ index: Int) -> some View {
        modifier(StaggeredAppear(index: index))
    }

    func revealOnScroll() -> some View {
        modifier(RevealOnScroll())
    }
}

// MARK: - Celebração

/// Selo de check que salta e solta faíscas, para confirmar uma ação (pagamento
/// registrado). Dispara a cada mudança de `trigger` e some sozinho.
private struct SuccessBurst: ViewModifier {

    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var visible = false

    private let sparks = 12

    func body(content: Content) -> some View {
        content
            .overlay {
                if visible {
                    ZStack {
                        ForEach(0..<sparks, id: \.self) { index in
                            let angle = Double(index) / Double(sparks) * 2 * .pi
                            Circle()
                                .fill(index.isMultiple(of: 2) ? Color.success : Color.brandSecondary)
                                .frame(width: 8, height: 8)
                                .offset(
                                    x: cos(angle) * 90 * progress,
                                    y: sin(angle) * 90 * progress
                                )
                                .scaleEffect(1 - progress * 0.6)
                                .opacity(Double(1 - progress))
                        }

                        Image(systemName: "checkmark")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 84, height: 84)
                            .background(Color.successGradient, in: Circle())
                            .scaleEffect(progress < 0.15 ? 0.4 : 1)
                            .opacity(Double(1 - max(0, progress - 0.7) / 0.3))
                    }
                    .allowsHitTesting(false)
                    .transition(.identity)
                }
            }
            .onChange(of: trigger) { _, _ in play() }
    }

    private func play() {
        guard !reduceMotion else { return }
        progress = 0
        visible = true
        withAnimation(.easeOut(duration: 0.8)) { progress = 1 }
        Task {
            try? await Task.sleep(for: .milliseconds(850))
            visible = false
        }
    }
}

extension View {
    /// Mostra o selo de sucesso sempre que `trigger` muda.
    func successBurst(trigger: Int) -> some View {
        modifier(SuccessBurst(trigger: trigger))
    }
}
