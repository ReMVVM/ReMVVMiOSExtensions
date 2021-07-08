//
//  SetViewControllersReducer.swift
//  ReMVVMExt
//
//  Created by Grzegorz Jurzak on 08/07/2021.
//

import ReMVVM

public struct SetViewControllersReducer: Reducer {

    public typealias Action = SetViewControllers

    public static func reduce(state: Navigation, with action: SetViewControllers) -> Navigation {

        let root: NavigationRoot
        // dismiss all modals without navigation
        var modals: [Navigation.Modal] = state.modals.reversed().drop { !$0.hasNavigation }.reversed()

        let factories = action.loadersWithFactory.map { $0.factory ?? state.factory }

        if let modal = modals.last, case .navigation = modal {
            modals = modals.dropLast() + [.navigation(factories)]
            root = state.root
        } else {
            let current = state.root.currentItem
            var stacks = state.root.stacks
            if let index = stacks.firstIndex(where: { $0.0 == current }) {
                let stack = factories
                stacks[index] = (current, stack)
            }

            root = NavigationRoot(current: state.root.currentItem, stacks: stacks)
        }

        return Navigation(root: root, modals: modals)
    }

}

public struct SetViewControllersMiddleware<State: NavigationState>: Middleware {

    public let uiState: UIState

    public init(uiState: UIState) {
        self.uiState = uiState
    }

    public func onNext(for state: State,
                       action: SetViewControllers,
                       interceptor: Interceptor<SetViewControllers, State>,
                       dispatcher: Dispatcher) {

        let uiState = self.uiState

        interceptor.next { state in
            // side effect

            //dismiss not needed modals
            uiState.dismiss(animated: action.animated,
                            number: uiState.modalControllers.count - state.navigation.modals.count)

            guard let navigationController = uiState.navigationController else {
                assertionFailure("SetViewControllersMiddleware: No navigation Controller")
                return
            }

            let controllers = action.loadersWithFactory.map { $0.loader.load() }
            navigationController.setViewControllers(controllers, animated: action.animated)

        }
    }
}



