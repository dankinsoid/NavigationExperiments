@_exported import UIKitNavigation
@_exported import UIKit
@_exported import SwiftNavigation
@_exported import UIKitNavigationShim
@_exported import IssueReporting

@MainActor
open class Coordinator: NSObject {

	open weak var parent: Coordinator?
	open func start(transaction: UITransaction) {}

	fileprivate var presentedByID: [UIBindingIdentifier: Presented] = [:]
	fileprivate var childrenByID: [UIBindingIdentifier: Child] = [:]
}

public extension Coordinator {
	
		/// Presents a view controller modally when a binding to a Boolean value you provide is true.
		///
		/// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
		///
		/// - Parameters:
		///   - isPresented: A binding to a Boolean value that determines whether to present the view
		///     controller.
		///   - onDismiss: The closure to execute when dismissing the view controller.
		///   - content: A closure that returns the view controller to display over the current view
		///     controller's content.
		@discardableResult
		func present(
			isPresented: UIBinding<Bool>,
			onDismiss: (() -> Void)? = nil,
			content: @escaping () -> UIViewController
		) -> ObserveToken {
			present(item: isPresented.toOptionalUnit, onDismiss: onDismiss) { _ in content() }
		}

		/// Presents a view controller modally using the given item as a data source for its content.
		///
		/// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
		///
		/// - Parameters:
		///   - item: A binding to an optional source of truth for the view controller. When `item` is
		///     non-`nil`, the item's content is passed to the `content` closure. You display this
		///     content in a view controller that you create that is displayed to the user. If `item`'s
		///     identity changes, the view controller is dismissed and replaced with a new one using the
		///     same process.
		///   - onDismiss: The closure to execute when dismissing the view controller.
		///   - content: A closure that returns the view controller to display over the current view
		///     controller's content.
		@discardableResult
		func present<Item: Identifiable>(
			item: UIBinding<Item?>,
			onDismiss: (() -> Void)? = nil,
			content: @escaping (Item) -> UIViewController
		) -> ObserveToken {
			present(item: item, id: \.id, onDismiss: onDismiss, content: content)
		}

		/// Presents a view controller modally using the given item as a data source for its content.
		///
		/// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
		///
		/// - Parameters:
		///   - item: A binding to an optional source of truth for the view controller. When `item` is
		///     non-`nil`, the item's content is passed to the `content` closure. You display this
		///     content in a view controller that you create that is displayed to the user. If `item`'s
		///     identity changes, the view controller is dismissed and replaced with a new one using the
		///     same process.
		///   - onDismiss: The closure to execute when dismissing the view controller.
		///   - content: A closure that returns the view controller to display over the current view
		///     controller's content.
		@_disfavoredOverload
		@discardableResult
		func present<Item: Identifiable>(
			item: UIBinding<Item?>,
			onDismiss: (() -> Void)? = nil,
			content: @escaping (UIBinding<Item>) -> UIViewController
		) -> ObserveToken {
			present(item: item, id: \.id, onDismiss: onDismiss, content: content)
		}

		/// Presents a view controller modally using the given item as a data source for its content.
		///
		/// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
		///
		/// - Parameters:
		///   - item: A binding to an optional source of truth for the view controller. When `item` is
		///     non-`nil`, the item's content is passed to the `content` closure. You display this
		///     content in a view controller that you create that is displayed to the user. If `item`'s
		///     identity changes, the view controller is dismissed and replaced with a new one using the
		///     same process.
		///   - id: The key path to the provided item's identifier.
		///   - onDismiss: The closure to execute when dismissing the view controller.
		///   - content: A closure that returns the view controller to display over the current view
		///     controller's content.
		@discardableResult
		func present<Item, ID: Hashable>(
			item: UIBinding<Item?>,
			id: @escaping (Item) -> ID,
			onDismiss: (() -> Void)? = nil,
			content: @escaping (Item) -> UIViewController
		) -> ObserveToken {
			present(item: item, id: id, onDismiss: onDismiss) {
				content($0.wrappedValue)
			}
		}

		/// Presents a view controller modally using the given item as a data source for its content.
		///
		/// Like SwiftUI's `sheet`, `fullScreenCover`, and `popover` view modifiers, but for UIKit.
		///
		/// - Parameters:
		///   - item: A binding to an optional source of truth for the view controller. When `item` is
		///     non-`nil`, the item's content is passed to the `content` closure. You display this
		///     content in a view controller that you create that is displayed to the user. If `item`'s
		///     identity changes, the view controller is dismissed and replaced with a new one using the
		///     same process.
		///   - id: The key path to the provided item's identifier.
		///   - onDismiss: The closure to execute when dismissing the view controller.
		///   - content: A closure that returns the view controller to display over the current view
		///     controller's content.
		@_disfavoredOverload
		@discardableResult
		func present<Item, ID: Hashable>(
			item: UIBinding<Item?>,
			id: @escaping (Item) -> ID,
			onDismiss: (() -> Void)? = nil,
			content: @escaping (UIBinding<Item>) -> UIViewController
		) -> ObserveToken {
			destination(item: item, id: id) { $item in
				content($item)
			} present: { child, transaction in
				guard let vc = transaction.viewController ?? UIWindow.key?.rootViewController?.topPresentedViewController else { return }
				if vc.presentedViewController != nil {
					vc.dismiss(
						animated: !transaction.uiKit.disablesAnimations
					) {
						onDismiss?()
						vc.present(child, animated: !transaction.uiKit.disablesAnimations)
					}
				} else {
					vc.present(child, animated: !transaction.uiKit.disablesAnimations)
				}
		
//				vc.topPresentedViewController
//					.present(child, animated: !transaction.uiKit.disablesAnimations)
			} dismiss: { child, transaction in
				child.dismiss(animated: !transaction.uiKit.disablesAnimations) {
					onDismiss?()
				}
			}
		}

		/// Pushes a view controller onto the receiver's stack when a binding to a Boolean value you
		/// provide is true.
		///
		/// Like SwiftUI's `navigationDestination(isPresented:)` view modifier, but for UIKit.
		///
		/// - Parameters:
		///   - isPresented: A binding to a Boolean value that determines whether to push the view
		///     controller.
		///   - content: A closure that returns the view controller to display onto the receiver's
		///     stack.
		@discardableResult
		func navigationDestination(
			isPresented: UIBinding<Bool>,
			content: @escaping () -> UIViewController
		) -> ObserveToken {
			navigationDestination(item: isPresented.toOptionalUnit) { _ in content() }
		}

		/// Pushes a view controller onto the receiver's stack using the given item as a data source for
		/// its content.
		///
		/// Like SwiftUI's `navigationDestination(item:)` view modifier, but for UIKit.
		///
		/// - Parameters:
		///   - item: A binding to an optional source of truth for the view controller. When `item` is
		///     non-`nil`, the item's content is passed to the `content` closure. You display this
		///     content in a view controller that you create that is displayed to the user.
		///   - content: A closure that returns the view controller to display onto the receiver's
		///     stack.
		@discardableResult
		func navigationDestination<Item>(
			item: UIBinding<Item?>,
			content: @escaping (Item) -> UIViewController
		) -> ObserveToken {
			navigationDestination(item: item) {
				content($0.wrappedValue)
			}
		}

		/// Pushes a view controller onto the receiver's stack using the given item as a data source for
		/// its content.
		///
		/// Like SwiftUI's `navigationDestination(item:)` view modifier, but for UIKit.
		///
		/// - Parameters:
		///   - item: A binding to an optional source of truth for the view controller. When `item` is
		///     non-`nil`, the item's content is passed to the `content` closure. You display this
		///     content in a view controller that you create that is displayed to the user.
		///   - content: A closure that returns the view controller to display onto the receiver's
		///     stack.
		@_disfavoredOverload
		@discardableResult
		func navigationDestination<Item>(
			item: UIBinding<Item?>,
			content: @escaping (UIBinding<Item>) -> UIViewController
		) -> ObserveToken {
			destination(item: item) { $item in
				content($item)
			} present: { child, transaction in
				guard
					let controller = transaction.viewController,
					let navigationController = controller.navigationController ?? controller as? UINavigationController
				else {
					reportIssue(
						"""
						Can't present navigation item: "navigationController" is "nil".
						"""
					)
					return
				}
				navigationController.pushViewController(
					child, animated: !transaction.uiKit.disablesAnimations
				)
			} dismiss: { child, transaction in
				guard
					let controller = transaction.viewController,
					let navigationController = controller.navigationController ?? controller as? UINavigationController
				else {
					reportIssue(
						"""
						Can't dismiss navigation item: "navigationController" is "nil".
						"""
					)
					return
				}
				navigationController.popFromViewController(
					child, animated: !transaction.uiKit.disablesAnimations
				)
			}
		}

		/// Presents a view controller when a binding to a Boolean value you provide is true.
		///
		/// This helper powers ``present(isPresented:onDismiss:content:)`` and
		/// ``UIKit/UINavigationController/pushViewController(isPresented:content:)`` and can be used to
		/// define custom transitions.
		///
		/// - Parameters:
		///   - isPresented: A binding to a Boolean value that determines whether to present the view
		///     controller.
		///   - content: A closure that returns the view controller to display.
		///   - present: The closure to execute when presenting the view controller.
		///   - dismiss: The closure to execute when dismissing the view controller.
		@discardableResult
		func destination(
			isPresented: UIBinding<Bool>,
			content: @escaping () -> UIViewController,
			present: @escaping (UIViewController, UITransaction) -> Void,
			dismiss:
				@escaping (
					_ child: UIViewController,
					_ transaction: UITransaction
				) -> Void
		) -> ObserveToken {
			destination(
				item: isPresented.toOptionalUnit,
				content: { _ in content() },
				present: present,
				dismiss: dismiss
			)
		}

		/// Presents a view controller using the given item as a data source for its content.
		///
		/// This helper powers ``navigationDestination(item:content:)-1gks3`` and can be used to define
		/// custom transitions.
		///
		/// - Parameters:
		///   - item: A binding to an optional source of truth for the view controller. When `item` is
		///     non-`nil`, the item's content is passed to the `content` closure. You display this
		///     content in a view controller that you create that is displayed to the user.
		///   - content: A closure that returns the view controller to display.
		///   - present: The closure to execute when presenting the view controller.
		///   - dismiss: The closure to execute when dismissing the view controller.
		@discardableResult
		func destination<Item>(
			item: UIBinding<Item?>,
			content: @escaping (UIBinding<Item>) -> UIViewController,
			present: @escaping (UIViewController, UITransaction) -> Void,
			dismiss:
				@escaping (
					_ child: UIViewController,
					_ transaction: UITransaction
				) -> Void
		) -> ObserveToken {
			destination(
				item: item,
				id: { _ in nil },
				content: content,
				present: present,
				dismiss: dismiss
			)
		}

		/// Presents a view controller using the given item as a data source for its content.
		///
		/// This helper powers ``present(item:onDismiss:content:)-4m7m3`` and can be used to define
		/// custom transitions.
		///
		/// - Parameters:
		///   - item: A binding to an optional source of truth for the view controller. When `item` is
		///     non-`nil`, the item's content is passed to the `content` closure. You display this
		///     content in a view controller that you create that is displayed to the user. If `item`'s
		///     identity changes, the view controller is dismissed and replaced with a new one using the
		///     same process.
		///   - id: The key path to the provided item's identifier.
		///   - content: A closure that returns the view controller to display.
		///   - present: The closure to execute when presenting the view controller.
		///   - dismiss: The closure to execute when dismissing the view controller.
	@discardableResult
	func destination<Item, ID: Hashable>(
		item: UIBinding<Item?>,
		id: KeyPath<Item, ID>,
		content: @escaping (UIBinding<Item>) -> UIViewController,
		present:
			@escaping (
				_ child: UIViewController,
				_ transaction: UITransaction
			) -> Void,
		dismiss:
			@escaping (
				_ child: UIViewController,
				_ transaction: UITransaction
			) -> Void
	) -> ObserveToken {
		destination(
			item: item,
			id: { $0[keyPath: id] },
			content: content,
			present: present,
			dismiss: dismiss
		)
	}

	@discardableResult
	func child<N: Coordinator>(
		isPresented: UIBinding<Bool>,
		content: @escaping () -> N
	) -> ObserveToken {
		child(
			item: isPresented.toOptionalUnit,
			content: { _ in content() }
		)
	}

	@discardableResult
	func child<Item: Identifiable, N: Coordinator>(
		item: UIBinding<Item?>,
		content: @escaping (UIBinding<Item>) -> N
	) -> ObserveToken {
		child(
			item: item,
			id: \.id,
			content: content
		)
	}

	@discardableResult
	func child<ID: Hashable, Item, N: Coordinator>(
		item: UIBinding<Item?>,
		id: @escaping (Item) -> ID,
		content: @escaping (UIBinding<Item>) -> N
	) -> ObserveToken {
		destination(
			item: item,
			id: { id($0) },
			content: content
		) { child, transaction in
			child.start(transaction: transaction)
		}
	}
}

private extension Coordinator {

	func destination<Item, N: Coordinator>(
		item: UIBinding<Item?>,
		id: @escaping (Item) -> AnyHashable?,
		content: @escaping (UIBinding<Item>) -> N,
		present:
		@escaping (
			_ child: N,
			_ transaction: UITransaction
		) -> Void
	) -> ObserveToken {
		let key = UIBindingIdentifier(item)
		return observe { [weak self] transaction in
			guard let self else { return }
			if let unwrappedItem = UIBinding(item) {
				if let child = childrenByID[key] {
					guard let childID = child.presentationID,
								childID != id(unwrappedItem.wrappedValue)
					else {
						return
					}
				}
				let child = content(unwrappedItem)
				child.parent = self
				self.childrenByID[key] = Child(child, id: id(unwrappedItem.wrappedValue))
				withUITransaction(transaction) {
					present(child, transaction)
				}
			} else if let child = childrenByID[key] {
				child.coordinator.parent = nil
				self.childrenByID[key] = nil
			}
		}
	}
	
	private func destination<Item>(
		item: UIBinding<Item?>,
		id: @escaping (Item) -> AnyHashable?,
		content: @escaping (UIBinding<Item>) -> UIViewController,
		present:
		@escaping (
			_ child: UIViewController,
			_ transaction: UITransaction
		) -> Void,
		dismiss:
		@escaping (
			_ child: UIViewController,
			_ transaction: UITransaction
		) -> Void
	) -> ObserveToken {
		let key = UIBindingIdentifier(item)
		var inFlightController: UIViewController?
		return observe { [weak self] transaction in
			guard let self else { return }
			if let unwrappedItem = UIBinding(item) {
				if let presented = presentedByID[key] {
					guard let presentationID = presented.presentationID,
								presentationID != id(unwrappedItem.wrappedValue)
					else {
						return
					}
				}
				let childController = content(unwrappedItem)
				let onDismiss = {
					[
						weak self,
						presentationID = id(unwrappedItem.wrappedValue)
					] in
					if let wrappedValue = item.wrappedValue, presentationID == id(wrappedValue) {
						inFlightController = self?.presentedByID[key]?.controller
						item.wrappedValue = nil
					}
				}
				childController._UIKitNavigation_onDismiss = onDismiss
//				if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
//					childController.traitOverrides.dismiss = UIDismissAction { _ in
//						onDismiss()
//					}
//				}
				self.presentedByID[key] = Presented(childController, id: id(unwrappedItem.wrappedValue))
				let work = {
					withUITransaction(transaction) {
						present(childController, transaction)
					}
				}
//				if transaction.viewController?._UIKitNavigation_hasViewAppeared != false {
					work()
//				} else {
//					transaction.viewController?._UIKitNavigation_onViewAppear.append(work)
//				}
			} else if let presented = presentedByID[key] {
				if let controller = presented.controller {
					var controllerToDismiss: UIViewController? = nil
					if inFlightController != nil {
						controllerToDismiss = inFlightController
						inFlightController = nil
//					} else if controller.presentedViewController != nil {
//						controllerToDismiss = self
					} else {
						controllerToDismiss = controller
					}
					if let controllerToDismiss {
						dismiss(controllerToDismiss, transaction)
					}
				}
				self.presentedByID[key] = nil
			}
		}
	}

	@MainActor
	final class Child {
		
		let coordinator: Coordinator
		let presentationID: AnyHashable?
		
		init(_ coordinator: Coordinator, id presentationID: AnyHashable? = nil) {
			self.coordinator = coordinator
			self.presentationID = presentationID
		}
	}
	
	@MainActor
	final class Presented {
		weak var controller: UIViewController?
		let presentationID: AnyHashable?
		deinit {
			// NB: This can only be assumed because it is held in a UIViewController and is guaranteed to
			//     deinit alongside it on the main thread. If we use this other places we should force it
			//     to be a UIViewController as well, to ensure this functionality.
			MainActor.assumeIsolated {
				guard let controller, controller.parent == nil else { return }
				controller.dismiss(animated: false)
			}
		}
		init(_ controller: UIViewController, id presentationID: AnyHashable? = nil) {
			self.controller = controller
			self.presentationID = presentationID
		}
	}
}

extension Bool {
	package struct Unit: Hashable, Identifiable {
		package var id: Unit { self }

		package init() {}
	}

	package var toOptionalUnit: Unit? {
		get { self ? Unit() : nil }
		set { self = newValue != nil }
	}
}

extension UIWindow {

	static var key: UIWindow? {
		UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap { $0.windows }
			.first { $0.isKeyWindow }
	}
}

extension UIViewController {

	var topPresentedViewController: UIViewController {
		presentedViewController?.topPresentedViewController ?? self
	}
	
	private var onDeinitWrapper: OnDeinit {
		if let wrapper = objc_getAssociatedObject(self, &Self.onDeinitKey) as? OnDeinit {
			 return wrapper
		 } else {
			 let wrapper = OnDeinit()
			 objc_setAssociatedObject(
				 self,
				 &Self.onDeinitKey,
				 wrapper,
				 .OBJC_ASSOCIATION_RETAIN_NONATOMIC
			 )
			 return wrapper
		 }
	}
	
	private static var onDeinitKey = 0
	
	func onDeinit(_ observer: @escaping @MainActor () -> Void) {
		onDeinitWrapper.add(observer)
	}

	final class OnDeinit {

		private var observers: [@MainActor () -> Void] = []

		deinit {
			for observer in observers {
				observer()
			}
		}
	
		func add(_ observer: @escaping @MainActor () -> Void) {
			observers.append(observer)
		}
	}
}

private enum CurrentViewControllerAssociatedKey: UITransactionKey {

	static var defaultValue: Value {
		Value()
	}

	struct Value {
		weak var controller: UIViewController?
	}
}

extension UITransaction {
	
	public var viewController: UIViewController? {
		get { self[CurrentViewControllerAssociatedKey.self].controller }
		set {
			var value = self[CurrentViewControllerAssociatedKey.self]
			value.controller = newValue
			self[CurrentViewControllerAssociatedKey.self] = value
		}
	}
}

extension UINavigationController {
	@discardableResult
	func popFromViewController(
		_ controller: UIViewController, animated: Bool
	) -> [UIViewController]? {
		guard let index = viewControllers.firstIndex(of: controller), index != 0 else { return nil }
		return popToViewController(viewControllers[index - 1], animated: animated)
	}
}
