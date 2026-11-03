//
//  Loading.swift
//  SubCheck
//
//  Indicadores de carregamento próprios, no lugar do `ProgressView` padrão.
//  Todos respeitam "Reduzir Movimento": sem animação eles continuam
//  legíveis, só não giram.
//

import SwiftUI

// MARK: - Arco pequeno

/// Arco girando com o gradiente da marca. Para espaços pequenos, dentro de
/// botões e linhas.
struct BrandSpinner: View {

    var size: CGFloat = 22
    var lineWidth: CGFloat = 2.5
    /// Cores do arco; troque por branco dentro de botões com fundo colorido.
    var colors: [Color] = [.brand.opacity(0.12), .brand, .brandSecondary]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angle = 0.0

    var body: some View {
        Circle()
            .trim(from: 0.05, to: 0.72)
            .stroke(
                AngularGradient(colors: colors, center: .center),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(angle))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 0.95).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
            .accessibilityLabel(L.t("Carregando…"))
    }
}

// MARK: - Três pontos

/// Três pontos que sobem e descem em sequência. Para esperas curtas em que
/// uma roda parece exagerada.
struct PulseDots: View {

    var color: Color = .brand
    var size: CGFloat = 9

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var up = false

    var body: some View {
        HStack(spacing: size * 0.7) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .offset(y: up ? -size * 0.6 : 0)
                    .opacity(up ? 1 : 0.5)
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 0.55)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.16),
                        value: up
                    )
            }
        }
        .frame(height: size * 1.8)
        .onAppear { up = true }
        .accessibilityLabel(L.t("Carregando…"))
    }
}

// MARK: - Anéis grandes

/// Dois anéis girando em sentidos opostos com a marca no centro. Usado nas
/// telas de espera em tela cheia.
struct OrbitLoader: View {

    var size: CGFloat = 104

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.brand.opacity(0.14), lineWidth: size * 0.06)

            Circle()
                .trim(from: 0, to: 0.32)
                .stroke(
                    Color.brandGradient,
                    style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round)
                )
                .rotationEffect(.degrees(spin ? 360 : 0))

            Circle()
                .trim(from: 0.55, to: 0.74)
                .stroke(
                    Color.brandSecondary.opacity(0.55),
                    style: StrokeStyle(lineWidth: size * 0.045, lineCap: .round)
                )
                .padding(size * 0.15)
                .rotationEffect(.degrees(spin ? -360 : 0))

            BrandMark(size: size * 0.4)
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                spin = true
            }
        }
        .accessibilityLabel(L.t("Carregando…"))
    }
}

// MARK: - Sobreposição de espera

/// Bloqueia a tela com um fundo fosco e o carregador da marca. Usado quando
/// o app está montando algo e o usuário não deve tocar em nada.
struct LoadingOverlay: View {

    var title: String
    var progress: Double?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                OrbitLoader()

                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                if let progress {
                    ProgressView(value: progress)
                        .tint(.brand)
                        .frame(maxWidth: 220)
                        .animation(.linear(duration: 0.1), value: progress)
                }
            }
            .padding(Spacing.xxl)
        }
        .transition(.opacity)
    }
}
