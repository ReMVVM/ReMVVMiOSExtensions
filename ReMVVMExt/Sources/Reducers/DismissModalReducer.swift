//
//  DismissModalReducer.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019. All rights reserved.
//

import ReMVVMCore

public struct DismissModalReducer: Reducer {
    public static func reduce(state: Navigation, with action: DismissModal) -> Navigation {
        guard !state.modals.isEmpty else { return state }

        var modals = state.modals
        if action.dismissAllViews {
            modals.removeAll()
        } else {
            modals.removeLast()
        }
        return Navigation(root: state.root, modals: modals)
    }
}

public struct DismissModalMiddleware<State: NavigationState>: Middleware {
    public let uiState: UIState

    public init(uiState: UIState) {
        self.uiState = uiState
    }

    public func onNext(for state: State,
                       action: DismissModal,
                       interceptor: Interceptor<DismissModal, State>,
                       dispatcher: Dispatcher) {

        let uiState = self.uiState

        interceptor.next { _ in
            // side effect
            NavigationDispatcher.main.async { completion in
                //dismiss not needed modals
                if action.dismissAllViews {
                    uiState.dismissAll(animated: action.animated, completion: completion)
                } else {
                    uiState.dismiss(animated: action.animated, completion: completion)
                }
            }
        }
    }
}
