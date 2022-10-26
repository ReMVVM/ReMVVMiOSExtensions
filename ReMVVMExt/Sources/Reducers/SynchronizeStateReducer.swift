//
//  SynchronizeStateReducer.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019. All rights reserved.
//

import Foundation
import ReMVVMCore
import UIKit

// needed to synchronize the state when user use back button or swipe gesture
struct SynchronizeStateReducer: Reducer {

    public typealias Action = SynchronizeState

    public static func reduce(state: Navigation, with action: SynchronizeState) -> Navigation {
        if action.type == .navigation {
            return PopReducer.reduce(state: state, with: Pop())
        } else {
            return DismissModalReducer.reduce(state: state, with: DismissModal())
        }
    }
}

//private var swizzle: Void = UIViewController.swizzleDidDisapear()
public final class SynchronizeStateMiddleware<State: NavigationState>: Middleware {
    public let uiState: UIState

    public init(uiState: UIState) {
//        _ = swizzle
        self.uiState = uiState
    }

    public func onNext(for state: State,
                       action: StoreAction,
                       interceptor: Interceptor<StoreAction, State>,
                       dispatcher: Dispatcher) {
//
//        DispatchQueue.main.async { [self] in
//            print(uiState.navigationController)
//        print(UINavigationController().delegate)
//        }
        
        if let action = action as? SynchronizeState {

            if  action.type == .navigation,
                let navigationCount = uiState.navigationController?.viewControllers.count,
                state.navigation.topStack.count > navigationCount {

                interceptor.next()
            } else if action.type == .modal, uiState.modalControllers.last?.isBeingDismissed == true {
                uiState.modalControllers.removeLast()
                interceptor.next { [weak self] _ in
                    self?.setupSynchronizeDelegate(dispatcher: dispatcher)
                }
            }
        } else {
            interceptor.next { [weak self] _ in
                self?.setupSynchronizeDelegate(dispatcher: dispatcher)
            }
        }
    }

//    private var synchronizeDelegate: SynchronizeDelegate?
    private func setupSynchronizeDelegate(dispatcher: Dispatcher) {
//        let navController = UINavigationController()
//        navController.delegate = nil
//        let d: UINavigationControllerDelegate? = navController.delegate
//        print("db: \(d == nil)")

//        DispatchQueue.main.async { [uiState] in
//            print(uiState.navigationController)
//            print(uiState.navigationController?.delegate)
//        }
//
//        synchronizeDelegate = SynchronizeDelegate(dispatcher: dispatcher,
//                                                  navigationController: uiState.navigationController,
//                                                  modal: uiState.modalControllers.last)
    }
}
//
//// swizzle
//private class SynchronizeDelegate: NSObject, UINavigationControllerDelegate {
//
//    let dispatcher: Dispatcher
//
//    // navigation controller delegate setup outside ReMVVMExt
//    weak var externalDelegate: UINavigationControllerDelegate?
//
//    init(dispatcher: Dispatcher, navigationController: UINavigationController?, modal: UIViewController?) {
//        self.dispatcher = dispatcher
//        super.init()
//
//        if let navigationController = navigationController {
//
//            if let delegate = navigationController.delegate as? SynchronizeDelegate {
//                externalDelegate = delegate.externalDelegate
//            } else {
//                externalDelegate = navigationController.delegate
//            }
//        }
//
//        navigationController?.delegate = self
//        modal?.synchronizeDelegate = self
//    }
//
//    override func forwardingTarget(for aSelector: Selector!) -> Any? {
//        externalDelegate?.responds(to: aSelector) == true ? externalDelegate : self
//    }
//
//    override func responds(to aSelector: Selector!) -> Bool {
//        super.responds(to: aSelector) || externalDelegate?.responds(to: aSelector) ?? false
//    }
//
//    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
//
//        externalDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
//        dispatcher.dispatch(action: SynchronizeState(.navigation))
//    }
//
//    func vievDidDisapear(controller: UIViewController, animated: Bool) {
//        dispatcher.dispatch(action: SynchronizeState(.modal))
//    }
//}
//
//private extension UIViewController {
//
//    private struct AssociatedKeys {
//        static var didDisapearClosureKey = "com.db.didDisapear"
//    }
//
//    var synchronizeDelegate: SynchronizeDelegate? {
//        get { (objc_getAssociatedObject(self, &AssociatedKeys.didDisapearClosureKey) as? WeakObjectContainer)?.object as? SynchronizeDelegate }
//        set { objc_setAssociatedObject(self, &AssociatedKeys.didDisapearClosureKey, WeakObjectContainer(with: newValue), .OBJC_ASSOCIATION_RETAIN) }
//    }
//
//    private class WeakObjectContainer {
//
//        weak var object: AnyObject?
//
//        public init(with object: AnyObject?) {
//            self.object = object
//        }
//    }
//
//    private typealias ViewDidDisappearFunction = @convention(c) (UIViewController, Selector, Bool) -> Void
//    private typealias ViewDidDisappearBlock = @convention(block) (UIViewController, Bool) -> Void
//
//    static func swizzleDidDisapear() {
//        var implementation: IMP?
//
//        let swizzledBlock: ViewDidDisappearBlock = { calledViewController, animated in
//            let selector = #selector(UIViewController.viewDidDisappear(_:))
//
//            calledViewController.synchronizeDelegate?.vievDidDisapear(controller: calledViewController, animated: true)
//
//            if let implementation = implementation {
//                let viewDidAppear: ViewDidDisappearFunction = unsafeBitCast(implementation, to: ViewDidDisappearFunction.self)
//                viewDidAppear(calledViewController, selector, animated)
//            }
//
//        }
//        implementation = swizzleViewDidDisappear(UIViewController.self, to: swizzledBlock)
//    }
//
//    private static func swizzleViewDidDisappear(_ class_: AnyClass, to block: @escaping ViewDidDisappearBlock) -> IMP? {
//
//        let selector = #selector(UIViewController.viewDidDisappear(_:))
//        let method: Method? = class_getInstanceMethod(class_, selector)
//        let newImplementation: IMP = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
//
//        if let method = method {
//            let types = method_getTypeEncoding(method)
//            return class_replaceMethod(class_, selector, newImplementation, types)
//        } else {
//            class_addMethod(class_, selector, newImplementation, "")
//            return nil
//        }
//    }
//}
