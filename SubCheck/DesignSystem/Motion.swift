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
