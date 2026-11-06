//
//  DeviceCapabilities.swift
//  SubCheck
//
//  O iOS não tem uma API pública "este iPhone tem Ilha Dinâmica?". Detectamos
//  pelo recuo superior da janela (a Ilha ocupa ~59–62 pt; o entalhe, 47–50) e,
//  quando a tela está deitada e o recuo some, pelo modelo do aparelho. Assim o
//  app não promete a Ilha onde ela não existe, e a Atividade ao Vivo na tela
//  de bloqueio segue valendo para qualquer iPhone.
//

import SwiftUI
import UIKit

enum DeviceCapabilities {

    /// Recuo superior mínimo (em pontos) de um iPhone com Ilha Dinâmica.
    static let islandInsetThreshold: CGFloat = 51

    /// Regra pura, para teste.
    static func hasIsland(safeAreaTop: CGFloat, modelIdentifier: String, isPhone: Bool) -> Bool {
        guard isPhone else { return false }
        if safeAreaTop > 0 { return safeAreaTop >= islandInsetThreshold }
        return modelHasIsland(modelIdentifier)
    }

    /// "iPhone16,1" → major 16. Ilha: 14 Pro (15,2/15,3), 15 (15,4/15,5) e 16+,
    /// menos o 16e (17,5), que tem entalhe.
    static func modelHasIsland(_ identifier: String) -> Bool {
        guard identifier.hasPrefix("iPhone") else { return false }
        let numbers = identifier.dropFirst("iPhone".count).split(separator: ",").compactMap { Int($0) }
        guard numbers.count == 2 else { return false }
        let (major, minor) = (numbers[0], numbers[1])
        if major == 15 { return minor >= 2 }
        if identifier == "iPhone17,5" { return false }
        return major >= 16
    }

    /// Resultado guardado depois da primeira leitura válida.
    private static var cached: Bool?

    static var hasDynamicIsland: Bool {
        if let cached { return cached }
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        let top = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? 0
        let value = hasIsland(safeAreaTop: top, modelIdentifier: modelIdentifier, isPhone: isPhone)
        if top > 0 { cached = value }
        return value
    }

    /// Atividades ao Vivo existem só no iPhone.
    static var supportsLiveActivities: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    static var modelIdentifier: String {
        #if targetEnvironment(simulator)
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulated }
        #endif
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }
}

/// Como chamar o recurso: "Ilha Dinâmica" só onde ela existe.
enum LiveSurface {

    static var hasIsland: Bool { DeviceCapabilities.hasDynamicIsland }

    static var name: String {
        hasIsland ? L.t("Ilha Dinâmica") : L.t("Atividade ao Vivo")
    }

    /// Escolhe o texto conforme o aparelho.
    static func text(island: String, noIsland: String) -> String {
        hasIsland ? L.t(island) : L.t(noIsland)
    }
}
