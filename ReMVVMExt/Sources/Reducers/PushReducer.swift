//
//  PushReducer.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019. All rights reserved.
//

import ReMVVM

public struct PushReducer: Reducer {

    public typealias Action = Push

    public static func reduce(state: Navigation, with action: Push) -> Navigation {

        let root: NavigationRoot
        // dismiss all modals without navigation
        var modals: [Navigation.Modal] = state.modals.reversed().drop { !$0.hasNavigation }.reversed()

        if let modal = modals.last, case .navigation(let stack) = modal {
            let newStack = updateStack(stack, for: action.pop)
            modals = modals.dropLast() + [.navigation(newStack + [action.controllerInfo.factory])]
            root = state.root
        } else {
            let current = state.root.currentItem
            var stacks = state.root.stacks
            if let index = stacks.firstIndex(where: { $0.0 == current }) {
                let stack = updateStack(stacks[index].1, for: action.pop) + [action.controllerInfo.factory]
                stacks[index] = (current, stack)
            }

            root = NavigationRoot(current: state.root.currentItem, stacks: stacks)
        }

        return Navigation(root: root, modals: modals)
    }

    private static func updateStack(_ stack: [ViewModelFactory], for pop: PopMode?) -> [ViewModelFactory] {
        guard let popMode = pop, stack.count > 1 else { return stack }

        switch popMode {
        case .pop(let count):
            let dropCount = min(count, stack.count)
            return Array(stack.dropLast(dropCount))
        case .popToRoot:
            return Array(stack.dropLast(stack.count - 1))
        }

    }
}

public struct PushMiddleware: AnyMiddleware {

    public let uiState: UIState

    public init(uiState: UIState) {
        self.uiState = uiState
    }

    public func onNext<State>(for state: State,
                            action: StoreAction,
                            interceptor: Interceptor<StoreAction, State>,
                            dispatcher: Dispatcher) where State: StoreState {

        guard state is NavigationState, let action = action as? Push else {
            interceptor.next()
            return
        }

        let uiState = self.uiState

        interceptor.next { state in
            // side effect
            guard let state = state as? NavigationState else { return }

            //dismiss not needed modals
            uiState.dismiss(animated: action.controllerInfo.animated,
                            number: uiState.modalControllers.count - state.navigation.modals.count)

            guard let navigationController = uiState.navigationController else {
                assertionFailure("PushMiddleware: No navigation Controller")
                return
            }

            // push controller
            let controller = action.controllerInfo.loader.load()
            //todo dg
//            if let topViewController = navigationController.topViewController {
//                let button = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
//                topViewController.navigationItem.backBarButtonItem = button
//            }

            if let pop = action.pop {
                var viewControllers = navigationController.viewControllers
                switch pop {
                case .popToRoot:
                    viewControllers = viewControllers.dropLast(viewControllers.count - 1)
                case .pop(let count):
                    let dropCount = min(count, viewControllers.count)
                    viewControllers = viewControllers.dropLast(dropCount)
                }

                navigationController.setViewControllers(viewControllers + [controller],
                                                        animated: action.controllerInfo.animated)
            } else {
                navigationController.pushViewController(controller, animated: action.controllerInfo.animated)
            }

        }
    }
}
