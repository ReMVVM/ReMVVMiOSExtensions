//
//  DismissModalReducer.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019. All rights reserved.
//

import ReMVVM

public struct DismissModalReducer: Reducer {

    public typealias Action = DismissModal

    public static func reduce(state: Navigation, with action: DismissModal) -> Navigation {

        var modals = state.modals
        if action.dismissAllViews {
            modals.removeAll()
        } else {
            modals.removeLast()
        }
        return Navigation(root: state.root, modals: modals)
    }

}

public struct DismissModalMiddleware: AnyMiddleware {

    public let uiState: UIState

    public init(uiState: UIState) {
        self.uiState = uiState
    }

    public func onNext<State>(for state: State,
                            action: StoreAction,
                            interceptor: Interceptor<StoreAction, State>,
                            dispatcher: Dispatcher) where State: StoreState {

        guard state is NavigationState, let action = action as? DismissModal else {
            interceptor.next()
            return
        }

        let uiState = self.uiState

        guard !uiState.modalControllers.isEmpty else { return }

        interceptor.next { _ in
            // side effect

            //dismiss not needed modals
            if action.dismissAllViews {
                uiState.dismissAll(animated: action.animated)
            } else {
                uiState.dismiss(animated: action.animated)
            }
        }

    }
}
