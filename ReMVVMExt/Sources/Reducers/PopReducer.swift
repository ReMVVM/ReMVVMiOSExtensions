//
//  PopReducer.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019. All rights reserved.
//

import ReMVVMCore

public struct PopReducer: Reducer {
    public static func reduce(state: Navigation, with action: Pop) -> Navigation {
        updateStateTree(state, for: action.mode)
    }

    private static func updateStateTree(_ stateTree: Navigation, for mode: PopMode) -> Navigation {
        switch mode {
        case .popToRoot, .resetStack:
            return popStateTree(stateTree, dropCount: stateTree.topStack.count - 1)
        case .pop(let count):
            return popStateTree(stateTree, dropCount: count)
        }
    }

    private static func popStateTree(_ navigation: Navigation, dropCount: Int) -> Navigation {
        //TODO ??? czy na pewno top stack ? nie powinien pop robic dissmiss modala ?
        guard dropCount > 0, navigation.topStack.count > dropCount else { return navigation }
        let root: NavigationRoot
        let modals: [Navigation.Modal]
        let newTopStack = Array(navigation.topStack.dropLast(dropCount))
        if navigation.modals.isEmpty { //no modal
            let current = navigation.root.currentItem
            var stacks = navigation.root.stacks
            if let index = stacks.firstIndex(where: { $0.0 == current }) {
                stacks[index] = (current, newTopStack)
            }

            root = NavigationRoot(current: current, stacks: stacks)
            modals = navigation.modals
        } else { // modal
            root = navigation.root
            modals = Array(navigation.modals.dropLast()) + [.navigation(newTopStack)]
        }

        return Navigation(root: root, modals: modals)
    }

}

public struct PopMiddleware<State: NavigationState>: Middleware {
    public let uiState: UIState

    public init(uiState: UIState) {
        self.uiState = uiState
    }

    public func onNext(for state: State,
                       action: Pop,
                       interceptor: Interceptor<Pop, State>,
                       dispatcher: Dispatcher)  {
        print(action)
        guard state.navigation.topStack.count > 1 else { return }

        interceptor.next { _ in
            // side effect
            switch action.mode {
            case .popToRoot, .resetStack:
                NavigationDispatcher.main.async { completion in
                    self.uiState.navigationController?.popToRootViewController(animated: action.animated,
                                                                               completion: completion)
                }
            case .pop(let count):
                if count > 1 {
                    let viewControllers = self.uiState.navigationController?.viewControllers ?? []
                    let dropCount = min(count, viewControllers.count - 1) - 1
                    let newViewControllers = Array(viewControllers.dropLast(dropCount))
                    NavigationDispatcher.main.async { completion in
                        self.uiState.navigationController?.setViewControllers(newViewControllers,
                                                                              animated: false,
                                                                              completion: completion)
                    }
                }
                NavigationDispatcher.main.async { completion in
                    self.uiState.navigationController?.popViewController(animated: action.animated, completion: completion)
                }
            }
        }
    }
}
