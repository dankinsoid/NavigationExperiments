import SwiftUI
import Perception

// MARK: - Main Payment Coordinator Flow

struct PaymentCoordinatorFlow: Flow {

    @Ref var route: PaymentRoute

    init(route: Ref<PaymentRoute>) {
        _route = route
    }

    @FlowBuilder
    func build(context: Context) -> any Flow {
        // Check if already paid
        if route.hasPaidPayload {
            PaymentProcessFlow(
                route: $route.paymentProcessRoute,
                startWithSuccess: true
            )
        } else {
            NavigationFlow($route.step) {
                SelectPaymentMethodScreen(
                    onPay: { method in
                        route.selectedMethod = method
                        route.step = .paymentProcess
                    },
                    onAddNewCard: {
                        route.step = .addCardDetails
                    },
                    onPaidSuccessfully: {
                        route.paymentProcessRoute.startWithSuccess = true
                        route.step = .paymentProcess
                    }
                )
                .tag(.selectPaymentMethod)
    
                CardDetailsScreen(
                    onCompletion: { payload in
                        route.paymentPayload = payload
                        route.step = .paymentProcess
                    },
                    onReload: {
                        route.step = .selectPaymentMethod
                    },
                    onClose: {
                        route.dismissFlow()
                    }
                )
                .tag(.addCardDetails)

                PaymentProcessFlow(
                    route: $route.paymentProcessRoute,
                    startWithSuccess: false
                )
                .tag(.paymentProcess)
            }
        }
    }
}

// MARK: - Payment Process Flow

struct PaymentProcessFlow: Flow {

    @Ref var route: PaymentProcessRoute
    let startWithSuccess: Bool

    init(route: Ref<PaymentProcessRoute>, startWithSuccess: Bool) {
        _route = route
        self.startWithSuccess = startWithSuccess
    }

    @FlowBuilder
    func build(context: Context) -> any Flow {
        NavigationFlow(path: $route.steps) { step in
            switch step {
            case .loading:
                LoadingScreen()

            case let .web(url):
                PaymentWebScreen(
                    url: url,
                    onRedirect: { redirectURL in
                        route.handleWebRedirect(redirectURL)
                    }
                )

            case let .error(error):
                PaymentFailureScreen(
                    error: error,
                    onRetry: {
                        route.retryPayment()
                    },
                    onClose: {
                        route.closeWithResult(.closeOnFailed)
                    }
                )

            case .success:
                PaymentResultScreen(
                    onBackToPayments: {
                        route.finishWith(.chooseMethod)
                    },
                    onPaymentSchedule: {
                        route.finishWith(.showPaymentSchedule)
                    },
                    onAdditionalAction: {
                        route.handleAdditionalAction()
                    }
                )
            }
        }
    }
}

// MARK: - Routes

@Perceptible
final class PaymentRoute {

    var step: Step = .selectPaymentMethod
    var hasPaidPayload: Bool = false
    var selectedMethod: PaymentMethod?
    var paymentPayload: PaymentPayload?
    var paymentProcessRoute = PaymentProcessRoute()

    enum Step: Hashable {

        case selectPaymentMethod
        case addCardDetails
        case paymentProcess
    }

    func dismissFlow() {
        // Mock dismiss
    }
}

@Perceptible
final class PaymentProcessRoute {

    var steps: [Step] = []
    var startWithSuccess: Bool = false
    var currentResult: PaymentProcessResult?

    enum Step: Hashable {
        case loading
        case web(URL)
        case error(PaymentError)
        case success
    }

    func handleWebRedirect(_ url: URL) {
        // Mock handling web redirect
        steps.append(.success)
    }

    func retryPayment() {
        steps = [.loading]
    }

    func closeWithResult(_ result: PaymentProcessResult) {
        currentResult = result
    }

    func finishWith(_ result: PaymentProcessResult) {
        currentResult = result
    }

    func handleAdditionalAction() {
        // Mock additional action
    }
}

// MARK: - Result Types

enum PaymentProcessResult {
    case done
    case showPaymentSchedule
    case chooseMethod
    case close
    case closeOnFailed
    case addNewPaymentMethod
}

enum PaymentCoordinatorResult {
    case done
    case showPaymentSchedule
    case cancelled
    case failed
    case addAnotherCard
}

// MARK: - Mock Screens

struct SelectPaymentMethodScreen: Flow {

    var onPay: @MainActor (PaymentMethod) -> Void = { _ in }
    var onAddNewCard: @MainActor () -> Void = {}
    var onPaidSuccessfully: @MainActor () -> Void = {}

    func build(context: Context) -> any Flow {
    }
}

struct CardDetailsScreen: Flow {

    var onCompletion: @MainActor (PaymentPayload) -> Void = { _ in }
    var onReload: @MainActor () -> Void = {}
    var onClose: @MainActor () -> Void = {}

    func build(context: Context) -> any Flow {
    }
}

struct LoadingScreen: Flow {

    func build(context: Context) -> any Flow {
    }
}

struct PaymentWebScreen: Flow {

    var url: URL
    var onRedirect: @MainActor (URL) -> Void = { _ in }

    func build(context: Context) -> any Flow {
    }
}

struct PaymentFailureScreen: Flow {
    var error: PaymentError
    var onRetry: @MainActor () -> Void = {}
    var onClose: @MainActor () -> Void = {}
    
    func build(context: Context) -> any Flow {
    }
}

struct PaymentResultScreen: Flow {
    var onBackToPayments: @MainActor () -> Void = {}
    var onPaymentSchedule: @MainActor () -> Void = {}
    var onAdditionalAction: @MainActor () -> Void = {}
    
    func build(context: Context) -> any Flow {
    }
}

// MARK: - Mock Data Types

struct PaymentPayloadPreparingData {
    var merchantName: String = "Merchant Name"
    var payload: PaymentPayload?
}

struct PaymentPayload: Hashable {
    var cardNumber: String = ""
    var expiryDate: String = ""
    var cvv: String = ""
}

struct PaymentMethod: Hashable {
    var id: String
    var name: String
    var type: PaymentMethodType

    enum PaymentMethodType: Hashable {
        case card
        case applePay
        case googlePay
        case tabby
    }
}

struct PaymentError: Hashable {
    var code: String
    var message: String
    var isRetryable: Bool
}

// MARK: - Usage Example

@MainActor
final class PaymentCoordinator {

    var paymentRoute = PaymentRoute()
    var window = UIWindow()

    func start() {
        window.setRootFlow {
            PaymentCoordinatorFlow(route: Ref(self, \.paymentRoute))
        }
    }

    func startWithPaidPayload() {
        paymentRoute.hasPaidPayload = true
        window.setRootFlow {
            PaymentCoordinatorFlow(route: Ref(self, \.paymentRoute))
        }
    }

    func deepLinkToCardDetails() {
        let routeService = RouteService(route: Ref(self, \.paymentRoute))
        routeService.deepLink {
            routeService.route.step = .addCardDetails
        }
    }
}
