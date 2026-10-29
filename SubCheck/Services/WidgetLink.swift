//
//  WidgetLink.swift
//  SubCheck
//
//  Links `subcheck://` usados pelos widgets para abrir o app na tela certa.
//  O esquema está declarado em `Config/Info.plist` (CFBundleURLTypes).
//  Compartilhado com a extensão de widget.
//

import Foundation

enum WidgetLink {

    static let scheme = "subcheck"

    static var dashboard: URL { url("dashboard") }

    static func subscription(_ id: UUID) -> URL { url("subscription/\(id.uuidString)") }

    static func category(_ category: String) -> URL { url("category/\(category)") }

    private static func url(_ path: String) -> URL {
        // O caminho é montado por nós, sempre válido.
        URL(string: "\(scheme)://\(path)")!
    }
}
