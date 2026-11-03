//
//  SharedModelContainer.swift
//  SubCheck
//
//  Single source of truth for the SwiftData stack. The store lives inside an
//  App Group so the widget extension can read the same data as the app.
//  When the App Group is unavailable (unsigned/dev builds) it falls back to
//  the app's private store so the app still runs.
//
//  Sincronização com iCloud (CloudKit) é opcional e só roda no app: a
//  extensão de widgets abre o mesmo arquivo sem CloudKit, e o histórico
//  persistente do SwiftData leva as mudanças dela para a nuvem depois.
//

import Foundation
import SwiftData

enum SharedModelContainer {

    /// Must match the App Group declared in both entitlements files.
    static let appGroupID = "group.com.viniciusmicarelli.subcheck"

    /// Contêiner do CloudKit; precisa existir no portal do desenvolvedor e
    /// em `Config/SubCheck.entitlements`.
    static let cloudKitContainerID = "iCloud.com.viniciusmicarelli.subcheck"

    /// Preferência gravada em `UserDefaults`; vale a partir do próximo
    /// lançamento, porque o contêiner é criado uma única vez.
    static let iCloudSyncKey = "iCloudSyncEnabled"

    static let schema = Schema([
        Subscription.self,
        PaymentRecord.self,
        DeletedSubscription.self
    ])

    static let shared: ModelContainer = makeContainer()

    /// `true` quando o usuário ligou a sincronização nas Ajustes.
    static var iCloudSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: iCloudSyncKey)
    }

    /// Extensões (widgets) terminam em `.appex`; só o app sincroniza.
    private static var isMainApp: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    /// `.automatic` ligaria o CloudKit sozinho assim que o entitlement
    /// existe, então o desligado é sempre explícito.
    private static var cloudDatabase: ModelConfiguration.CloudKitDatabase {
        iCloudSyncEnabled && isMainApp ? .private(cloudKitContainerID) : .none
    }

    private static func makeContainer() -> ModelContainer {
        let groupConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupID),
            cloudKitDatabase: cloudDatabase
        )

        if let container = try? ModelContainer(for: schema, configurations: groupConfig) {
            return container
        }

        // CloudKit indisponível (conta, entitlement ou esquema): segue local.
        let groupLocal = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupID),
            cloudKitDatabase: .none
        )
        if let container = try? ModelContainer(for: schema, configurations: groupLocal) {
            return container
        }

        // Fallback: private store (App Group entitlement missing).
        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: localConfig)
        } catch {
            // Last resort so the app never crashes on launch.
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: memoryConfig)
        }
    }
}
