import SwiftUI
@_exported import UIKit
@_exported import Perception

// BASE

@MainActor
public struct FlowContext {

    var isAnimated: Bool
    var isNavigationController: Bool
    let _provide: @MainActor (UIViewController) -> Void
    let controllers: [UIViewController]

    init(
        isAnimated: Bool = true,
        controllers: [UIViewController],
        isNavigationController: Bool = false,
        provide: @escaping @MainActor (UIViewController) -> Void
    ) {
        self.isAnimated = isAnimated
        self.controllers = controllers
        self._provide = provide
        self.isNavigationController = isNavigationController
    }

    public func provide(controller: UIViewController) {
        self._provide(controller)
    }
}

public struct FlowTraits {
    
    public var tag: AnyHashable?
}

@MainActor
public protocol Flow {

    typealias Context = FlowContext

    /// Builds the flow with the given context.
    /// - Parameter context: The context to build the flow with.
    /// - Warning: Never call this method directly.
    @FlowBuilder
    func build(context: Context) -> any Flow
    func modify(traits: inout FlowTraits, context: Context)
    func flattened(context: Context) -> [any Flow]
}

extension Flow {
    
    public func modify(traits: inout FlowTraits, context: Context) {}
    public func flattened(context: Context) -> [any Flow] { [self] }

    func update(context: Context) {
        if self is NonFlow {
            return
        }
        build(context: context)
            .update(context: context)
    }
}

@propertyWrapper
@dynamicMemberLookup
public struct Ref<Value> {

    public var wrappedValue: Value {
        get { get() }
        nonmutating set { set(newValue) }
    }
    
    public var projectedValue: Ref<Value> {
        return self
    }

    public let get: () -> Value
    public let set: (Value) -> Void
    
    public init(wrappedValue: Value) {
        self.get = { wrappedValue }
        self.set = { _ in }
    }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.get = get
        self.set = set
    }

    public init<T>(_ object: T, _ keyPath: ReferenceWritableKeyPath<T, Value>) {
        self.get = { object[keyPath: keyPath] }
        self.set = { object[keyPath: keyPath] = $0 }
    }

    public static func constant(_ value: Value) -> Ref<Value> {
        return Ref(get: { value }, set: { _ in })
    }
    
    public subscript<Subject>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> Ref<Subject> {
        Ref<Subject>(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
    
    public static var mock: Ref {
        Ref<Value>(get: { fatalError("Ref.mock.get called") }, set: { _ in fatalError("Ref.mock.set called") })
    }
}

@MainActor
@resultBuilder
public enum FlowBuilder {

    @inlinable
    public static func buildBlock(_ components: (any Flow)...) -> any Flow {
        buildArray(components)
    }

    @inlinable
    public static func buildOptional(_ component: (any Flow)?) -> any Flow {
        buildArray(component.map { [$0] } ?? [])
    }

    @inlinable
    public static func buildEither(first component: any Flow) -> any Flow {
        component
    }

    @inlinable
    public static func buildEither(second component: any Flow) -> any Flow {
        component
    }

    @inlinable
    public static func buildArray(_ components: [any Flow]) -> any Flow {
        FlowArray(body: components)
    }

    @inlinable
    public static func buildExpression(_ expression: some Flow) -> any Flow {
        expression
    }

    @inlinable
    public static func buildExpression(_ expression: any Flow) -> any Flow {
        expression
    }
}

public struct NonFlow: Flow {

    public func flattened(context: Context) -> [any Flow] {
        []
    }

    public func build(context: Context) -> any Flow {
        fatalError("NonFlow cannot be used as a Flow")
        return self
    }
}

public struct FlowArray: Flow {

    public let body: [any Flow]

    public init(body: [any Flow]) {
        self.body = body
    }

    public func flattened(context: Context) -> [any Flow] {
        body.flatMap { $0.flattened(context: context) }
    }
    
    public func build(context: Context) -> any Flow {
        for flow in body {
            flow.update(context: context)
        }
        return NonFlow()
    }
}

// Flows

public struct Screen: Flow {
    
    private let screenType: UIViewController.Type
    private let createScreen: @MainActor (Context) -> UIViewController
    private let updateScreen: @MainActor (UIViewController, Context) -> Void

    public init<Content: UIViewController>(
        _ content: @escaping @MainActor (Context) -> Content,
        update: @escaping @MainActor (Content, Context) -> Void = { _, _ in }
    ) {
        self.screenType = Content.self
        createScreen = {
            content($0)
        }
        updateScreen = { viewController, context in
            if let typedVC = viewController as? Content {
                update(typedVC, context)
            }
        }
    }

    public init<Content: UIViewController>(
        _ content: @escaping @autoclosure @MainActor () -> Content,
        update: @escaping @MainActor (Content, Context) -> Void = { _, _ in }
    ) {
        self.init({ _ in  content() }, update: update)
    }

//    public init<Content: View>(
//        @ViewBuilder _ content: @escaping @MainActor () -> Content
//    ) {
//        
//    }
    
    public func build(context: Context) -> any Flow {
    
        context.provide(controller: createScreen(context))
    
        return NonFlow()
    }
}

public struct NavigationFlow: Flow {

    private let screens: @MainActor (Context) -> [any Flow]
//    private

    public init(@FlowBuilder _ content: @escaping @MainActor () -> any Flow) {
        screens = { content().flattened(context: $0) }
    }

    public init<ID: Hashable>(_ id: Ref<ID>, @TagsBuilder<ID> _ content: @escaping @MainActor () -> [Tag<ID>]) {
        screens = { ctx in
            let flows = content().flatMap { $0.flattened(context: ctx) }.map {
                var traits = FlowTraits()
                $0.modify(traits: &traits, context: ctx)
                return (traits.tag, $0)
            }
            let tag = AnyHashable(id.wrappedValue)
            if let i = flows.lastIndex(where: { $0.0 == tag }) {
                return flows[0...i].map(\.1)
            } else {
                return []
            }
        }
    }

    public init<ID: Hashable, S: Sequence<ID>>(path: Ref<S>, _ content: [ID: any Flow]) {
        screens = { ctx in
            path.wrappedValue.flatMap { id in
                content[id]?.flattened(context: ctx) ?? []
            }
        }
    }

    public init<ID, S: Sequence<ID>>(path: Ref<S>, @FlowBuilder _ content: @escaping @MainActor (ID) -> any Flow) {
        screens = { ctx in
            path.wrappedValue.flatMap { id in
                content(id).flattened(context: ctx)
            }
        }
    }

    public func flattened(context: Context) -> [any Flow] {
        if context.isNavigationController {
            return screens(context)
        } else {
            return [self]
        }
    }

    public func build(context: Context) -> any Flow {
        if context.isNavigationController {
            var context = context
            context.isNavigationController = true
            return FlowArray(body: screens(context))
        } else {
            return Screen { _ in
                UINavigationController()
            } update: { [screens] controller, context in
                var newControllers: [UIViewController] = []
                let context = FlowContext(
                    isAnimated: context.isAnimated,
                    controllers: controller.viewControllers,
                    isNavigationController: true
                ) {
                    newControllers.append($0)
                }

                for flow in screens(context) {
                    flow.update(context: context)
                }
    
                if newControllers != controller.viewControllers {
                    controller.setViewControllers(
                        newControllers,
                        animated: context.isAnimated && controller.viewControllers.last !== newControllers.last
                    )
                }
            }
        }
    }
}

public struct Tag<ID: Hashable>: Flow {

    public let tag: ID
    public let body: any Flow

    public init(_ tag: ID, @FlowBuilder _ body: () -> any Flow) {
        self.tag = tag
        self.body = body()
    }

    public func build(context: Context) -> any Flow {
        body
    }

    public func flattened(context: Context) -> [any Flow] {
        body.flattened(context: context).map { body in
            Tag(tag) { body }
        }
    }

    public func modify(traits: inout FlowTraits, context: Context) {
        traits.tag = tag
    }
}

extension Flow {

    public func tag<ID: Hashable>(_ id: ID) -> Tag<ID> {
        Tag(id) {
            self
        }
    }
}

@resultBuilder
public enum TagsBuilder<ID: Hashable> {
    
    @inlinable
    public static func buildBlock(_ components: [Tag<ID>]...) -> [Tag<ID>] {
        components.flatMap { $0 }
    }

    @inlinable
    public static func buildOptional(_ component: [Tag<ID>]?) -> [Tag<ID>] {
        component ?? []
    }

    @inlinable
    public static func buildEither(first component: [Tag<ID>]) -> [Tag<ID>] {
        component
    }

    @inlinable
    public static func buildEither(second component: [Tag<ID>]) -> [Tag<ID>] {
        component
    }

    @inlinable
    public static func buildArray(_ components: [[Tag<ID>]]) -> [Tag<ID>] {
        components.flatMap { $0 }
    }
    
    @inlinable
    public static func buildLimitedAvailability(_ component: [Tag<ID>]) -> [Tag<ID>] {
        component
    }
    
    @inlinable
    public static func buildExpression(_ expression: Tag<ID>) -> [Tag<ID>] {
        [expression]
    }
}

public struct Present: Flow {

    public init(
        isPresented: Ref<Bool>,
        @FlowBuilder _ content: () -> any Flow
    ) {}

    public init<Item>(
        item: Ref<Item?>,
        @FlowBuilder _ content: (Item) -> any Flow
    ) {}

    public func build(context: Context) -> any Flow {
        return NonFlow()
    }
}

// UIKit integration

extension UIWindow {

    public func setRootFlow(
        @FlowBuilder _ content: () -> any Flow
    ) {
        
    }
}

extension UIViewController {

    @MainActor
    public func presentFlow(
        @FlowBuilder _ content: @escaping @Sendable @MainActor () -> any Flow
    ) {
        let id = UUID()
        FlowsCoordinator().updateFlow(id: id) {
            content()
        }
    }
}

@MainActor
public final class FlowsCoordinator: Sendable {

    private let deinitTracker = DeinitTracker()

    deinit {
        let tracker = deinitTracker
        DispatchQueue.main.async {
            // this trigger perception tracking to notify dependents that this coordinator is gone and they should clean up
            tracker.isDeinited = true
        }
    }

    public func updateFlow(
        id: some Hashable & Sendable,
        @FlowBuilder _ content: @escaping @Sendable @MainActor () -> any Flow
    ) {
        let flow = withPerceptionTracking {
            _ = deinitTracker.isDeinited // observe deinitTracker to track lifecycle
            return content()
        } onChange: { [weak self] in
            guard let self else { return }
            // main.async throttles updates to avoid rapid changes and guarantees UI updates happen on main thread
            DispatchQueue.main.async {
                self.updateFlow(id: id, content)
            }
        }
    }

    private struct SendableHashable: @unchecked Sendable, Hashable {

        let id: AnyHashable
    }
}

@MainActor
@Perceptible
final class DeinitTracker {

    var isDeinited = false
}

// SwiftUI integration

extension View {
    
    public func flow(
        @FlowBuilder _ content: () -> any Flow
    ) -> some View {
        self
    }
}

@MainActor
public struct RouteService<Route> {
    
    @Ref public var route: Route
    
    public init(route: Ref<Route>) {
        self._route = route
    }
    
    public func withoutAnimation<T>(_ updates: @MainActor () throws -> T) rethrows -> T {
        try updates()
    }
    
    public func withAnimation<T>(_ updates: @MainActor () throws -> T) rethrows -> T {
        try updates()
    }

    public func deepLink<T>(_ updates: @MainActor () throws -> T) rethrows -> T {
        try updates()
    }
}
