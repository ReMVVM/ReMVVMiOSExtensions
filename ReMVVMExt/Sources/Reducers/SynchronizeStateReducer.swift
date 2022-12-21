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

private var swizzle: Void = UIViewController.swizzleDidDisapear()
public final class SynchronizeStateMiddleware<State: NavigationState>: Middleware {
    public let uiState: UIState

    public init(uiState: UIState) {
        _ = swizzle
        self.uiState = uiState
    }

    public func onNext(for state: State,
                       action: StoreAction,
                       interceptor: Interceptor<StoreAction, State>,
                       dispatcher: Dispatcher) {
        
        if let action = action as? SynchronizeState {

            if  action.type == .navigation,
                let navigationCount = uiState.navigationController?.viewControllers.count,
                state.navigation.topStack.count > navigationCount {

                interceptor.next()
            } else if action.type == .modal, uiState.modalControllers.last?.isBeingDismissed == true {
                uiState.modalControllers.removeLast()
                
                interceptor.next()
            }
        } else {
            interceptor.next()
        }
    }
}

//swizzle viewDidDissapear
private extension UIViewController {

    private struct AssociatedKeys {
        static var didDisapearClosureKey = "com.db.didDisapear"
    }

    private typealias ViewDidDisappearFunction = @convention(c) (UIViewController, Selector, Bool) -> Void
    private typealias ViewDidDisappearBlock = @convention(block) (UIViewController, Bool) -> Void

    static func swizzleDidDisapear() {
        var implementation: IMP?

        let swizzledBlock: ViewDidDisappearBlock = { calledViewController, animated in
            let selector = #selector(UIViewController.viewDidDisappear(_:))

            ReMVVM.Dispatcher().dispatch(action: SynchronizeState(.modal))

            if let implementation = implementation {
                let viewDidAppear: ViewDidDisappearFunction = unsafeBitCast(implementation, to: ViewDidDisappearFunction.self)
                viewDidAppear(calledViewController, selector, animated)
            }

        }
        implementation = swizzleViewDidDisappear(UIViewController.self, to: swizzledBlock)
    }

    private static func swizzleViewDidDisappear(_ class_: AnyClass, to block: @escaping ViewDidDisappearBlock) -> IMP? {

        let selector = #selector(UIViewController.viewDidDisappear(_:))
        let method: Method? = class_getInstanceMethod(class_, selector)
        let newImplementation: IMP = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))

        if let method = method {
            let types = method_getTypeEncoding(method)
            return class_replaceMethod(class_, selector, newImplementation, types)
        } else {
            class_addMethod(class_, selector, newImplementation, "")
            return nil
        }
    }
}

open class ReMVVMNavigationController: UINavigationController {
    
    @objc private var _delegate = Delegate()
    
    public override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        super.delegate = _delegate
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        super.delegate = _delegate
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        super.delegate = _delegate
    }
    
    public override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        super.delegate = _delegate
    }
    
    open override var delegate: UINavigationControllerDelegate? {
        get { _delegate.delegate }
        set { _delegate.delegate = newValue }
    }
    
    private class Delegate: NSObject, UINavigationControllerDelegate {
        @ReMVVM.Dispatcher private var dispatcher
        
        var delegate: UINavigationControllerDelegate?
        
        override func forwardingTarget(for aSelector: Selector!) -> Any? {
            delegate?.responds(to: aSelector) == true ? delegate : self
        }
    
        override func responds(to aSelector: Selector!) -> Bool {
            return super.responds(to: aSelector) || delegate?.responds(to: aSelector) ?? false
        }
        
        func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {

            delegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
            dispatcher.dispatch(action: SynchronizeState(.navigation))
        }
    }
}
