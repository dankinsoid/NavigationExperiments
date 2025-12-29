import Foundation

public final class PaymentCoordinator: Coordinator {

    public var step: Step = .start
    public var successPayment = SuccessPaymentCoordinator()

    public func route(step: Step, context: CoordinatorContext) -> Assembly {
        switch step {
        case .start:
            context
                .style(.fullScreen)
                .router
                .screen { context in
                    UIViewController()
                }
                .from(.root)

        case let .child(step):
            successPayment
                .route(step: step, context: context)
        }
    }

    public enum Step {

        case start
        case child(SuccessPaymentCoordinator.Step)
    }
}

public final class PaymentFactory {

    public static func makePaymentScreen() -> Screen {
        Screen { context in
            UIViewController()
        }
    }
}

public final class SuccessPaymentCoordinator: Coordinator {

    public func route(step: Step, context: CoordinatorContext) -> Assembly {
        
    }
    
    public enum Step {
        
    }
}
