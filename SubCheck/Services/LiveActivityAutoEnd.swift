//
//  LiveActivityAutoEnd.swift
//  SubCheck
//
//  Encerra a Live Activity depois de 1 minuto na tela. Sem servidor de push o
//  iOS só deixa o app agir enquanto ele roda; por isso pedimos um pouco de
//  tempo em segundo plano. Se o iOS não der esse tempo (o app foi suspenso
//  antes), `endExpired()` encerra na próxima vez que o app acordar.
//

import ActivityKit
import UIKit

enum LiveActivityAutoEnd {

    @MainActor
    static func install() {
        LiveActivityService.scheduleAutoEnd = { activity in
            Task { @MainActor in
                var task = UIBackgroundTaskIdentifier.invalid
                task = UIApplication.shared.beginBackgroundTask(withName: "subcheck.liveActivity.end") {
                    UIApplication.shared.endBackgroundTask(task)
                    task = .invalid
                }
                let elapsed = Date().timeIntervalSince(activity.attributes.startedAt)
                let remaining = max(0, LiveActivityLifecycle.visibleSeconds - elapsed)
                try? await Task.sleep(for: .seconds(remaining))
                await activity.end(nil, dismissalPolicy: .immediate)
                if task != .invalid { UIApplication.shared.endBackgroundTask(task) }
            }
        }
    }
}
