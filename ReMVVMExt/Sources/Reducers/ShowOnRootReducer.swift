//
//  ShowOnRootReducer.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019. All rights reserved.
//

import ReMVVM

struct ShowOnRootReducer: Reducer {

    public static func reduce(state: Navigation, with action: ShowOnRoot) -> Navigation {

        let current = NavigationRoot.Main.single
        let stacks = [(current, [action.controllerInfo.factory])]
        let root = NavigationRoot(current: current, stacks: stacks)
        return Navigation(root: root, modals: [])
    }
}

public struct ShowOnRootMiddleware: AnyMiddleware {

    public let uiState: UIState

    public init(uiState: UIState) {
        self.uiState = uiState
    }

    public func onNext<State>(for state: State,
                            action: StoreAction,
                            interceptor: Interceptor<StoreAction, State>,
                            dispatcher: Dispatcher) where State: StoreState {

        guard state is NavigationState, let action = action as? ShowOnRoot else {
            interceptor.next()
            return
        }

        let uiState = self.uiState

        interceptor.next { _ in // newState - state variable is used below
            // side effect

            uiState.setRoot(controller: action.controllerInfo.loader.load(),
                            animated: action.controllerInfo.animated,
                            navigationBarHidden: action.navigationBarHidden)

            // dismiss modals
            uiState.rootViewController.dismiss(animated: true, completion: nil)
        }
    }
}
