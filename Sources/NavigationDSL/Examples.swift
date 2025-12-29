//import SwiftUI
//import Perception
//
//public struct AuthFlow: Flow {
//
//    @Ref var route: AuthRoute
//
//    public init(_ route: Ref<AuthRoute>) {
//        self._route = route
//    }
//
//    @FlowBuilder
//    public var body: some Flow {
//        Navigation($route.step) {
//            UserPhoneScreen()
//                .tag(AuthRoute.Steps.userphone)
//
//            if route.isNewUser {
//                PasswordScreen()
//                    .tag(AuthRoute.Steps.password)
//            }
//
//            OTPScreen()
//                .tag(AuthRoute.Steps.otp)
//        }
//
//        Present(item: $route.detailItem) { item in
//           OTPSheeet()
//        }
//    }
//}
//
//@Perceptible
//public final class AuthRoute: Codable {
//
//    public var step: Steps = .userphone
//
//    public var detailItem: DetailFeature.State?
//    public var isNewUser: Bool = false
//    public var otpRoute: OTPRoute?
//
//    public enum Steps: Hashable {
//
//        case userphone
//        case password
//        case otp
//    }
//}
//
//struct AnyRoute {
//    
//    
//}
//
//@MainActor
//final class RouteAppDelegate {
//
//    var authRoute = AuthRoute()
//    var window = UIWindow()
//
//    func didLaunch() {
//        window.setRootFlow {
//            AuthFlow(Ref(self, \.authRoute))
//        }
//    }
//
//    func deepLinkToSheet() {
//        let routeService = RouteService(route: Ref(self, \.authRoute))
//        
//        routeService.deepLink {
//            routeService.route.isPresented = true
//        }
//    }
//}
