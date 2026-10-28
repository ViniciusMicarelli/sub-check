//
//  ViewsManifest.swift
//  SubCheck
//
//  Registry of all destination views
//

import SwiftUI

// MARK: - Destination Views

// Navigation Stack Destinations
public enum NavigationDestinationViews: String, CaseIterable {
    case dashboard = "DashboardDestinationView"
    case subscriptions = "SubscriptionsDestinationView"
    case addSubscription = "AddSubscriptionDestinationView"
    case editSubscription = "EditSubscriptionDestinationView"
    case history = "HistoryDestinationView"
    case report = "ReportDestinationView"
    case settings = "SettingsDestinationView"
}

// MARK: - View Registration

public class ViewsManifest {
    private let viewRegistry: [String: () -> any View] = [:]
    private var routeToView: [String: String] = [:]
    
    static let shared = ViewsManifest()
    
    private init() {}
    
    // MARK: - Registration
    
    public func register<D: View>(_ view: D, for path: String) {
        routeToView[path] = view.description
    }
    
    public func loadView(for path: String) -> any View? {
        if let viewName = routeToView[path] {
            return viewRegistry[viewName]()
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    ViewsManifest.shared
}
