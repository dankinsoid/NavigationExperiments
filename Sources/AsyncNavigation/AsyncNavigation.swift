import UIKit

@MainActor
public protocol Screen<Event> {

    associatedtype Controller: UIViewController
    associatedtype Event

    func create(onEvent: @escaping @MainActor (Event) -> Void) -> Controller
}

@MainActor
class Coordinator {
    
    func example() async throws(CancellationError) {
        let method = try await push(SelectPaymentMethodScreen()).wait()
        switch method {
        case .creditCard:
            let cardDetails = try await push(CardDetailsScreen()).wait()
            
        case .applePay:
            print("Apple Pay selected")
            
        }
    }

    @discardableResult
    func present<T>(_ screen: some Screen<T>) async -> ScreenCoordinator<T> {
        ScreenCoordinator<T>()
    }

    @discardableResult
    func push<T>(_ screen: some Screen<T>) async -> ScreenCoordinator<T> {
        ScreenCoordinator<T>()
    }
}

@MainActor
struct ScreenCoordinator<Event> {

    private weak var controller: UIViewController?

    func wait() async throws(CancellationError) -> Event {
        fatalError()
    }
}

struct SelectPaymentMethodScreen: Screen {

    func create(onEvent: @escaping @MainActor (PaymentMethod) -> Void) -> UIViewController {
        UIViewController()
    }

    enum PaymentMethod {

        case creditCard
        case applePay	
    }
}

struct CardDetailsScreen: Screen {

    func create(onEvent: @escaping @MainActor (CardDetails) -> Void) -> UIViewController {
        UIViewController()
    }

    struct CardDetails {

        let cardNumber: String
        let expiryDate: String
        let cvv: String
    }
}
