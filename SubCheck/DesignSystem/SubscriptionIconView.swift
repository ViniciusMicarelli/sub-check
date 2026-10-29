//
//  SubscriptionIconView.swift
//  SubCheck
//
//  Desenha o ícone de uma assinatura num círculo: logo de marca empacotado,
//  SF Symbol ou imagem baixada de uma URL.
//

import SwiftUI

struct SubscriptionIconView: View {

    let icon: SubscriptionIcon
    /// Cor usada quando o ícone não traz uma cor própria de marca.
    let fallbackColor: Color
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().fill(background)
            glyph
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    // MARK: - Glifo

    @ViewBuilder
    private var glyph: some View {
        switch icon {
        case .brand(let id):
            brandGlyph(id)
        case .symbol(let name):
            symbolGlyph(name, color: .white)
        case .remote(let url):
            RemoteIconView(url: url) {
                symbolGlyph("photo", color: .white)
            }
        }
    }

    @ViewBuilder
    private func brandGlyph(_ id: String) -> some View {
        if let brand = BrandIconCatalog.icon(id: id) {
            if let asset = brand.asset, UIImage(named: asset) != nil {
                Image(asset)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(BrandColor.glyph(brand.hex ?? "000000"))
                    .frame(width: size * 0.52, height: size * 0.52)
            } else {
                symbolGlyph(brand.symbol, color: .white)
            }
        } else {
            symbolGlyph("questionmark", color: .white)
        }
    }

    private func symbolGlyph(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color)
    }

    // MARK: - Fundo

    private var background: Color {
        if let brand = icon.brandID.flatMap({ BrandIconCatalog.icon(id: $0) }),
           let hex = brand.hex {
            return BrandColor.fill(hex)
        }
        return fallbackColor
    }
}

/// Imagem remota com cache em disco. No widget não há acesso à rede, então o
/// ícone aparece assim que houver uma cópia em cache.
struct RemoteIconView<Placeholder: View>: View {

    private let url: URL
    private let placeholder: Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder()
        // Já tenta o cache em disco de forma síncrona (útil no widget).
        _image = State(initialValue: RemoteIconStore.cachedImage(for: url))
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder
            }
        }
        .task(id: url) {
            guard image == nil, !isLoading else { return }
            isLoading = true
            image = await RemoteIconStore.load(url)
            isLoading = false
        }
    }
}
