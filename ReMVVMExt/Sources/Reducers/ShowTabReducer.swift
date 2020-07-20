//
//  ShowTabReducer.swift
//  ReMVVMExt
//
//  Created by DGrzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019. All rights reserved.
//

import Loaders
import ReMVVM
import UIKit

typealias NavigationType = [AnyNavigationItem]
extension NavigationRoot {
    var navigationType: NavigationType { stacks.map { $0.0 } }
}

extension NavigationItem where Self: CaseIterable {
    static var navigationType: NavigationType { allCases.map { AnyNavigationItem($0) }}
}

struct ShowReducer: Reducer {

    public static func reduce(state: Navigation, with action: Show) -> Navigation {

        let current = action.item
        var stacks: [(AnyNavigationItem, [ViewModelFactory])]
        if action.navigationType == state.root.navigationType { //check the type is the same
            stacks = state.root.stacks.map {
                //TODO add second tap (make it configurable)
                guard $0.0 == current, $0.1.isEmpty else { return $0 }
                return ($0.0, [action.controllerInfo.factory])
            }
        } else {
            stacks = action.navigationType.map {
                guard $0 == current else { return ($0, []) }
                return ($0, [action.controllerInfo.factory])
            }
        }
        let root = NavigationRoot(current: current, stacks: stacks)
        return Navigation(root: root, modals: [])
    }
}

public struct ShowMiddleware: AnyMiddleware {

    public let uiState: UIState

    public init(uiState: UIState) {
        self.uiState = uiState
    }

    public func onNext<State>(for state: State, action: StoreAction, interceptor: Interceptor<StoreAction, State>, dispatcher: Dispatcher) where State : StoreState {

        guard let navigationState = state as? NavigationState, let navigationAction = action as? Show else {
            interceptor.next(action: action)
            return
        }

//TODO add second tap
//        if let rootState = state as? NavigationTreeContainingState, rootState.navigationTree.tree.stack.count > 1
//            && navigationState.navigationTree.tree.current == tabAction.tab.any {
//            interceptor.next(action: action) { [uiState] _ in
//                (uiState.rootViewController as? TabBarViewController)?
//                    .topNavigation?.popToRootViewController(animated: true)
//            }
//            return
//        }

//TODO
        guard navigationState.navigation.root.currentItem != navigationAction.item else { return }

        interceptor.next(action: action) { [uiState] state in

            let wasTabOnTop = navigationState.navigation.root.navigationType == navigationAction.navigationType
                && uiState.rootViewController is NavigationContainerController

            let containerController: NavigationContainerController
            if wasTabOnTop {
                containerController = uiState.rootViewController as! NavigationContainerController
            } else {
                let config = uiState.config.navigationConfigs.first { $0.navigationType == navigationAction.navigationType }
                if case let .custom(configurator) = config?.config {
                    containerController = configurator(navigationAction.navigationType)
                } else {
                    let tabController = TabBarViewController(config: config)
                    tabController.loadViewIfNeeded()

                    containerController = tabController
                }
            }

            //set up current if empty (or reset)
            if let top = containerController.currentNavigationController, top.viewControllers.isEmpty {
                top.setViewControllers([navigationAction.controllerInfo.loader.load()],
                animated: false)
            }

            if !wasTabOnTop {
                uiState.setRoot(controller: containerController,
                                animated: navigationAction.controllerInfo.animated,
                                navigationBarHidden: navigationAction.navigationBarHidden)
            }

            // dismiss modals
            uiState.rootViewController.dismiss(animated: true, completion: nil)
        }
    }
}
