//
//  ShowModalReducer.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019. All rights reserved.
//

import ReMVVM
import UIKit

public struct ShowModalReducer: Reducer {

    public typealias Action = ShowModal

    public static func reduce(state: Navigation, with action: ShowModal) -> Navigation {

        let factory = action.controllerInfo.factory
        let modal: Navigation.Modal = action.withNavigationController ? .navigation([factory]) : .single(factory)
        // dismiss all modals without navigation
        let modals = state.modals.reversed().drop { !$0.hasNavigation }.reversed() + [modal]

        return Navigation(root: state.root, modals: modals)
    }
}

public struct ShowModalMiddleware: AnyMiddleware {

    public let uiState: UIState
    public init(uiState: UIState) {
        self.uiState = uiState
    }

    public func onNext<State>(for state: State,
                            action: StoreAction,
                            interceptor: Interceptor<StoreAction, State>,
                            dispatcher: Dispatcher) where State: StoreState {

        guard state is NavigationState, let action = action as? ShowModal else {
            interceptor.next()
            return
        }

        let uiState = self.uiState

        var controller: UIViewController?
        // block if already on screen
        // TODO use some id maybe ? 
        if !action.showOverSelfType {
            controller = action.controllerInfo.loader.load()
            if let modal = uiState.modalControllers.last, type(of: modal) == type(of: controller!) {
                return
            }
        }

        interceptor.next { state in
            // side effect
            guard let state = state as? NavigationState else { return }

            //dismiss not needed modals
            uiState.dismiss(animated: action.controllerInfo.animated,
                            number: uiState.modalControllers.count - state.navigation.modals.count + 1)

            let newModal: UIViewController
            if action.withNavigationController {

                let navController = uiState.config.navigationController()
                let viewController = controller ?? action.controllerInfo.loader.load()

                navController.viewControllers = [viewController]
                navController.modalTransitionStyle = viewController.modalTransitionStyle
                navController.modalPresentationStyle = viewController.modalPresentationStyle
                newModal = navController
            } else {
                newModal = controller ?? action.controllerInfo.loader.load()
            }

            newModal.modalPresentationStyle = action.presentationStyle
            uiState.present(newModal, animated: action.controllerInfo.animated)
        }
    }
}
