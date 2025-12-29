@_exported  import SwiftUI
@_exported import Perception
import RouteComposer

public protocol Assembly {
    
}

@MainActor
public protocol Coordinator<Step> {

    associatedtype Step
    func route(step: Step, context: CoordinatorContext) -> Assembly
}

@MainActor
public struct CoordinatorContext {

    public var isAnimated = true
    
    /// Dynamic traits associated with the coordinator context.
    public var traits = Traits()
}

extension CoordinatorContext {

    @MainActor
    public struct Traits {

        private var storage: [AnyHashable: Any] = [:]

        public subscript<Value>(key: WritableKeyPath<Traits, Value>) -> Value? {
            get { storage[key] as? Value }
            set { storage[key] = newValue }
        }
    }
}

extension CoordinatorContext {

    public func with<Value: Sendable>(_ key: WritableKeyPath<Traits, Value>, _ value: Value) -> CoordinatorContext {
        var copy = self
        copy.traits[keyPath: key] = value
        return copy
    }

    public func transform<Value: Sendable>(_ key: WritableKeyPath<Traits, Value>, _ transform: (inout Value) -> Void) -> CoordinatorContext {
        var copy = self
        transform(&copy.traits[keyPath: key])
        return copy
    }

    public func animated(_ animated: Bool = true) -> CoordinatorContext {
        var copy = self
        copy.isAnimated = animated
        return copy
    }
}

@MainActor
public protocol Presenter {
    
    func show(controller: UIViewController, context: CoordinatorContext) async
}

public struct PushPresenter: Presenter {
    
    public init() {}
    
    public func show(controller: UIViewController, context: CoordinatorContext) async {
        
    }
}

public struct BottomSheetPresenter: Presenter {
    
    public init() {}
    
    public func show(controller: UIViewController, context: CoordinatorContext) async {
        
    }
}

public struct ModalPresenter: Presenter {
    
    public init() {}
    
    public func show(controller: UIViewController, context: CoordinatorContext) async {
        
    }
}

extension Presenter where Self == ModalPresenter {

    public static var fullScreen: ModalPresenter {
        ModalPresenter()
    }
}

extension Presenter where Self == BottomSheetPresenter {
    
    public static var bottomSheet: BottomSheetPresenter {
        BottomSheetPresenter()
    }
}

extension Presenter where Self == PushPresenter {
    
    public static var push: PushPresenter {
        PushPresenter()
    }
}

extension CoordinatorContext.Traits {
    
    public var presenter: Presenter {
        get { self[\.presenter] ?? PushPresenter() }
        set { self[\.presenter] = newValue }
    }
    
    public var interceptors: [any RoutingInterceptor] {
        get { self[\.interceptors] ?? [] }
        set { self[\.interceptors] = newValue }
    }
}

extension CoordinatorContext {
    
    public func style(_ presenter: Presenter) -> CoordinatorContext {
        var copy = self
        copy.traits.presenter = presenter
        return copy
    }
    
    public func interceptor(_ interceptor: any RoutingInterceptor) -> CoordinatorContext {
        var copy = self
        copy.traits.interceptors.append(interceptor)
        return copy
    }
}

extension CoordinatorContext {

    public var router: Router {
        Router()
    }
    
    @MainActor
    public struct Router {
        
        @MainActor
        public func screen<Screen: UIViewController>(
            _ screen: @escaping () -> Screen
        ) -> ScreenAssembly<Screen> {
            ScreenAssembly(factory: screen)
        }
    }
    
    @MainActor
    public struct CoordinatorAssembly<CoordinatorType: Coordinator>: Assembly {
        
    }

    @MainActor
    public struct ScreenAssembly<Screen: UIViewController>: Assembly {
        
        private var finder: any Finder = ClassFinder<Screen, CoordinatorContext>()
        private var factory: any Factory
        
        public init<F: Factory>(factory: F) where F.ViewController == Screen, F.Context == CoordinatorContext {
            self.factory = factory
        }
        
        public init(factory: @escaping () -> Screen) {
            self.factory = ClosureFactory { _ in
                factory()
            }
        }
        
        public init(factory: @escaping (CoordinatorContext) -> Screen) {
            self.factory = ClosureFactory { context in
                factory(context)
            }
        }
        
        public func finder<F: Finder>(_ finder: F) -> Self {
            self
        }
    
        public func from(_ step: DestinationStep<Screen, CoordinatorContext>) -> Self {
            self
        }
    }

    public struct ClosureFactory<ViewController: UIViewController>: Factory {
        
        let _build: (CoordinatorContext) -> ViewController
        
        public func build(with context: CoordinatorContext) throws -> ViewController {
            _build(context)
        }
    }
}
