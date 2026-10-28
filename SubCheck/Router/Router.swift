//
//  Router.swift
//  SubCheck
//
//  Centralized router for navigation management
//

import SwiftUI

// MARK: - Routes

enum Route: String {
    case dashboard
    case subscriptions
    case addSubscription
    case editSubscription
    case settings
    case history
    case report
    
    var path: String {
        switch self {
        case .dashboard:
            return "dashboard"
        case .subscriptions:
            return "subscriptions"
        case .addSubscription:
            return "add-subscription"
        case .editSubscription:
            return "edit-subscription"
        case .settings:
            return "settings"
        case .history:
            return "history"
        case .report:
            return "report"
        }
    }
    
    var destination: String {
        switch self {
        case .dashboard:
            return "DashboardDestinationView"
        case .subscriptions:
            return "SubscriptionsDestinationView"
        case .addSubscription:
            return "AddSubscriptionDestinationView"
        case .editSubscription:
            return "EditSubscriptionDestinationView"
        case .settings:
            return "SettingsDestinationView"
        case .history:
            return "HistoryDestinationView"
        case .report:
            return "ReportDestinationView"
        }
    }
    
    var isEditable: Bool {
        switch self {
        case .editSubscription:
            return true
        default:
            return false
        }
    }
}

// MARK: - AnyType

enum AnyType: Hashable {
    case view(View)
    case identifier(String)
    
    var identifier: String {
        switch self {
        case .view(let view):
            return view.description
        case .identifier(let id):
            return id
        }
    }
}

// MARK: - Navigation Parameters

struct NavigationParameters {
    let subscriptionId: UUID?
    
    var encoding: [String: Any] {
        var dict: [String: Any] = [:]
        if let id = subscriptionId {
            dict["subscriptionId"] = id.uuidString
        }
        return dict
    }
    
    init(subscriptionId: UUID? = nil) {
        self.subscriptionId = subscriptionId
    }
}

// MARK: - RouteHandler Protocol

protocol RouteHandler: Identifiable, Hashable {
    var id: String { get }
    
    associatedtype Destination: View
    
    func resolveParameters(_ parameters: NavigationParameters) -> Destination
    func canHandle(_ parameters: NavigationParameters) -> Bool
    func handle(parameters: NavigationParameters) -> Bool
}

// MARK: - Handlers

// MARK: - Default Handlers

struct DashboardHandler: RouteHandler {
    let id = "dashboard"
    
    func resolveParameters(_ parameters: NavigationParameters) -> DashboardDestinationView {
        DashboardDestinationView()
    }
    
    func canHandle(_ parameters: NavigationParameters) -> Bool {
        return true
    }
    
    func handle(parameters: NavigationParameters) -> Bool {
        return true
    }
}

struct SubscriptionsHandler: RouteHandler {
    let id = "subscriptions"
    
    func resolveParameters(_ parameters: NavigationParameters) -> SubscriptionsDestinationView {
        SubscriptionsDestinationView()
    }
    
    func canHandle(_ parameters: NavigationParameters) -> Bool {
        return true
    }
    
    func handle(parameters: NavigationParameters) -> Bool {
        return true
    }
}

struct AddSubscriptionHandler: RouteHandler {
    let id = "add-subscription"
    
    func resolveParameters(_ parameters: NavigationParameters) -> AddSubscriptionDestinationView {
        AddSubscriptionDestinationView()
    }
    
    func canHandle(_ parameters: NavigationParameters) -> Bool {
        return true
    }
    
    func handle(parameters: NavigationParameters) -> Bool {
        return true
    }
}

struct EditSubscriptionHandler: RouteHandler {
    let id = "edit-subscription"
    
    func resolveParameters(_ parameters: NavigationParameters) -> EditSubscriptionDestinationView {
        var subscription = Subscription()
        if let id = parameters.subscriptionId {
            subscription.id = id
        }
        return EditSubscriptionDestinationView(subscription: subscription)
    }
    
    func canHandle(_ parameters: NavigationParameters) -> Bool {
        return parameters.subscriptionId != nil
    }
    
    func handle(parameters: NavigationParameters) -> Bool {
        guard let subscriptionId = parameters.subscriptionId else {
            return false
        }
        return true
    }
}

struct SettingsHandler: RouteHandler {
    let id = "settings"
    
    func resolveParameters(_ parameters: NavigationParameters) -> SettingsDestinationView {
        SettingsDestinationView()
    }
    
    func canHandle(_ parameters: NavigationParameters) -> Bool {
        return true
    }
    
    func handle(parameters: NavigationParameters) -> Bool {
        return true
    }
}

struct HistoryHandler: RouteHandler {
    let id = "history"
    
    func resolveParameters(_ parameters: NavigationParameters) -> HistoryDestinationView {
        HistoryDestinationView()
    }
    
    func canHandle(_ parameters: NavigationParameters) -> Bool {
        return true
    }
    
    func handle(parameters: NavigationParameters) -> Bool {
        return true
    }
}

struct ReportHandler: RouteHandler {
    let id = "report"
    
    func resolveParameters(_ parameters: NavigationParameters) -> ReportDestinationView {
        ReportDestinationView()
    }
    
    func canHandle(_ parameters: NavigationParameters) -> Bool {
        return true
    }
    
    func handle(parameters: NavigationParameters) -> Bool {
        return true
    }
}

// MARK: - NavigationRouter

@MainActor
class NavigationRouter: ObservableObject {
    @Published private(set) var currentPath: String = "dashboard"
    @Published private(set) var destination: AnyType = .identifier("DashboardDestinationView")
    @Published private(set) var parameters: NavigationParameters = .init()
    @Published private(set) var hasBackButton: Bool = false
    @Published private(set) var presentationType: PresentationType = .normal
    
    private var routeHandlers: [String: RouteHandler] = [:]
    private var parameterStack: [String] = []
    
    enum PresentationType: String, CaseIterable {
        case normal
        case sheet
        case fullscreen
        
        var destinationModifier: String {
            switch self {
            case .normal:
                return "modifier"
            case .sheet:
                return "sheet"
            case .fullscreen:
                return "fullScreenCover"
            }
        }
    }
    
    init() {
        registerHandler(for: .dashboard)
    }
    
    // MARK: - Registration
    
    func registerHandler<T: RouteHandler>(_ handler: T) {
        routeHandlers[handler.id] = handler
    }
    
    // MARK: - Navigation
    
    @MainActor
    func push<T: RouteHandler>(_ handler: T) {
        parameterStack.append(handler.id)
        parameters = NavigationParameters(subscriptionId: nil)
        currentPath = handler.path
        updateDestination(handler: handler)
        updateHasBackButton()
    }
    
    @MainActor
    func pop() {
        guard !parameterStack.isEmpty else { return }
        parameterStack.removeLast()
        currentPath = parameterStack.isEmpty ? "dashboard" : parameterStack.last ?? "dashboard"
        updateDestination()
        updateHasBackButton()
    }
    
    @MainActor
    func popTo<T: RouteHandler>(_ handler: T) {
        if parameterStack.contains(handler.id) {
            parameterStack.removeAll { $0 != handler.id }
        }
        parameterStack.append(handler.id)
        currentPath = handler.path
        updateDestination(handler: handler)
        updateHasBackButton()
    }
    
    @MainActor
    func showAsSheet<T: RouteHandler>(_ handler: T) {
        parameterStack.append(handler.id)
        parameters = NavigationParameters(subscriptionId: nil)
        currentPath = handler.path
        presentationType = .sheet
        updateDestination(handler: handler)
        updateHasBackButton()
    }
    
    @MainActor
    func dismissSheet() {
        if presentationType == .sheet {
            presentationType = .normal
        }
        pop()
    }
    
    @MainActor
    func navigate(to path: String, parameters: NavigationParameters? = nil) {
        if let route = Route(rawValue: path) {
            push(route)
        } else if let custom = parameters?["destination"] as? String {
            push(path: custom)
        }
        if let navParams = parameters {
            self.parameters = navParams
        }
        currentPath = path
        updateDestination(fromPath: path)
        updateHasBackButton()
    }
    
    @MainActor
    func navigateBack() {
        pop()
    }
    
    @MainActor
    func popToPath(_ path: String) {
        if let route = Route(rawValue: path) {
            popTo(route)
        }
    }
    
    // MARK: - Helpers
    
    private func updateDestination(handler: RouteHandler) {
        if let handler = routeHandlers[handler.id] {
            destination = handler.resolveParameters(parameters)
        }
    }
    
    private func updateDestination() {
        if let handler = routeHandlers[currentPath] {
            destination = handler.resolveParameters(parameters)
        }
    }
    
    private func updateDestination(fromPath path: String) {
        if let route = Route(rawValue: path) {
            if let handler = routeHandlers[route.id] {
                destination = handler.resolveParameters(parameters)
            }
        }
    }
    
    private func updateHasBackButton() {
        hasBackButton = !parameterStack.isEmpty
    }
    
    func parameterStackCount() -> Int {
        return parameterStack.count
    }
    
    func currentRoute() -> Route? {
        return Route(rawValue: currentPath)
    }
    
    func parameters(_ key: String) -> Any? {
        return parameters.encoding[key]
    }
    
    func present<T: RouteHandler>(_ handler: T) {
        showAsSheet(handler)
    }
    
    func presentPath<T: RouteHandler>(_ handler: T) {
        push(handler)
    }
}

// MARK: - RouterStack

struct RouterStack: View {
    @ObservedObject var router: NavigationRouter
    
    @State private var currentDestination: AnyView
    @State private var presentationType: NavigationRouter.PresentationType = .normal
    @State private var hasBackButton = false
    
    private var content: some View {
        ZStack {
            NavigationStack {
                currentDestination
                    .modifier(presentationType.destinationModifier)
                    .environmentObject(router)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        if router.hasBackButton {
                            ToolbarItem(placement: .navigation) {
                                Button("← Voltar") {
                                    router.navigateBack()
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .topBarFrame) {
                            Menu {
                                Button("Dashboard") {
                                    router.navigate(to: "dashboard")
                                }
                                Button("Assinaturas") {
                                    router.navigate(to: "subscriptions")
                                }
                                Button("Configurações") {
                                    router.navigate(to: "settings")
                                }
                            } label: {
                                Image(systemName: "chevron.up.chevron.down")
                            }
                        }
                        
                        // Dismiss on tap gesture
                        if router.presentationType == .sheet {
                            Button("✕") {
                                router.dismissSheet()
                            }
                            .font(.title2)
                            .foregroundColor(.primary)
                        }
                    }
            }
        }
    }
    
    var body: some View {
        content
            .background(backgroundView)
            .onTapGesture(maximumDistance: 0) {
                if router.presentationType == .sheet {
                    router.dismissSheet()
                }
            }
    }
    
    private var backgroundView: some View {
        Rectangle()
            .fill(Color(.systemBackground))
    }
    
    func update() {
        currentDestination = AnyView(router.destination)
        presentationType = router.presentationType
        hasBackButton = router.hasBackButton
    }
    
    init(router: NavigationRouter) {
        self._router = ObjectWrapper(router)
        self.update()
    }
}

// MARK: - Preview

#Preview {
    RouterStack(router: NavigationRouter())
}
