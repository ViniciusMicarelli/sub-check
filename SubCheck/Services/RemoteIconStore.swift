//
//  RemoteIconStore.swift
//  SubCheck
//
//  Cache em disco das imagens de ícone informadas por URL. Fica dentro do
//  App Group para que o widget também consiga exibir o mesmo ícone.
//

import Foundation
import UIKit

enum RemoteIconStore {

    /// Lê a imagem já baixada, se existir. Leitura síncrona para que o widget
    /// (que não pode esperar por rede) consiga usar o ícone.
    static func cachedImage(for url: URL) -> UIImage? {
        if url.isFileURL { return UIImage(contentsOfFile: url.path) }

        guard let file = cacheFile(for: url),
              let data = try? Data(contentsOf: file) else { return nil }
        return UIImage(data: data)
    }

    /// Devolve a imagem do cache ou baixa da rede e guarda para a próxima vez.
    static func load(_ url: URL) async -> UIImage? {
        if let cached = cachedImage(for: url) { return cached }

        guard let (data, response) = try? await URLSession.shared.data(from: url) else { return nil }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 200
        guard status < 400, let image = UIImage(data: data) else { return nil }

        if let file = cacheFile(for: url) {
            try? data.write(to: file, options: .atomic)
        }
        return image
    }

    /// Limpa todas as imagens baixadas.
    static func clear() {
        guard let directory else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Privado

    private static var directory: URL? {
        let base = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedModelContainer.appGroupID)
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let base else { return nil }

        let folder = base.appendingPathComponent("RemoteIcons", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static func cacheFile(for url: URL) -> URL? {
        directory?.appendingPathComponent("\(stableHash(url.absoluteString)).img")
    }

    /// FNV-1a de 64 bits — `hashValue` muda entre execuções do app.
    private static func stableHash(_ string: String) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return String(hash, radix: 16)
    }
}
