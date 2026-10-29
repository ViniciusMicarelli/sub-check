//
//  IconPickerView.swift
//  SubCheck
//
//  Seletor de ícone: catálogo de marcas já incluídas no app, detecção
//  automática pelo nome e imagem a partir de um endereço (URL).
//

import SwiftUI

struct IconPickerView: View {

    @Environment(\.dismiss) private var dismiss

    /// Nome do serviço — usado para sugerir uma marca automaticamente.
    let serviceName: String
    /// Cor de fallback (categoria) para marcas sem logo empacotado.
    let fallbackColor: Color
    /// Ícone resultante da detecção automática, usado na prévia.
    let automaticIcon: SubscriptionIcon
    /// Ícone escolhido atualmente (`nil` = automático).
    let current: SubscriptionIcon?
    let onSelect: (SubscriptionIcon?) -> Void

    @State private var query = ""
    @State private var urlText = ""

    private var suggestion: BrandIcon? { BrandIconCatalog.match(name: serviceName) }
    private var results: [BrandIcon] { BrandIconCatalog.search(query) }

    private var typedURL: URL? {
        let text = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host() != nil else { return nil }
        return url
    }

    var body: some View {
        NavigationStack {
            List {
                automaticSection
                if query.isEmpty, let suggestion {
                    suggestedSection(suggestion)
                }
                urlSection
                brandsSection
            }
            .navigationTitle("Ícone")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: Text(L.t("Buscar marca")))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Seções

    private var automaticSection: some View {
        Section {
            selectionRow(
                title: L.t("Automático (pelo nome)"),
                subtitle: automaticSubtitle,
                icon: automaticIcon,
                isSelected: current == nil
            ) {
                select(nil)
            }
        } footer: {
            Text("O ícone é escolhido pela marca ou categoria do serviço.")
        }
    }

    private func suggestedSection(_ brand: BrandIcon) -> some View {
        Section(L.t("iconPicker.suggested", serviceName)) {
            selectionRow(
                title: brand.name,
                subtitle: brand.hasLogo ? L.t("Logo incluído no app") : L.t("Ícone genérico"),
                icon: brand.icon,
                isSelected: current == brand.icon
            ) {
                select(brand.icon)
            }
        }
    }

    private var urlSection: some View {
        Section {
            TextField("https://exemplo.com/logo.png", text: $urlText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .font(.callout)

            Button {
                guard let url = typedURL else { return }
                select(.remote(url))
            } label: {
                Label("Baixar e usar esta imagem", systemImage: "arrow.down.circle")
            }
            .disabled(typedURL == nil)

            if let url = typedURL {
                HStack(spacing: Spacing.md) {
                    SubscriptionIconView(icon: .remote(url), fallbackColor: fallbackColor, size: 44)
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        } header: {
            Text("Imagem por endereço")
        } footer: {
            Text("Cole o link de uma imagem (PNG, JPG ou SVG). Ela fica guardada no aparelho.")
        }
    }

    private var brandsSection: some View {
        Section(results.isEmpty ? L.t("Marcas") : L.t("iconPicker.brandsCount", results.count)) {
            if results.isEmpty {
                Text(L.t("iconPicker.noMatch", query))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4),
                    spacing: Spacing.md
                ) {
                    ForEach(results) { brand in
                        brandCell(brand)
                    }
                }
                .padding(.vertical, Spacing.xs)
                .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.md,
                                          bottom: Spacing.sm, trailing: Spacing.md))
            }
        }
    }

    // MARK: - Células

    private func selectionRow(
        title: String,
        subtitle: String,
        icon: SubscriptionIcon,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                SubscriptionIconView(icon: icon, fallbackColor: fallbackColor, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.brand)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func brandCell(_ brand: BrandIcon) -> some View {
        Button {
            select(brand.icon)
        } label: {
            VStack(spacing: Spacing.xs) {
                ZStack(alignment: .bottomTrailing) {
                    SubscriptionIconView(icon: brand.icon, fallbackColor: fallbackColor, size: 52)

                    if current == brand.icon {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.brand)
                            .offset(x: 4, y: 2)
                    }
                }

                Text(brand.name)
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(brand.name)
    }

    // MARK: - Ações

    private var automaticSubtitle: String {
        guard let suggestion else { return L.t("Categoria do serviço") }
        return suggestion.name
    }

    private func select(_ icon: SubscriptionIcon?) {
        Haptics.impact()
        onSelect(icon)
        dismiss()
    }
}
