//
//  ReMVVMExtension.swift
//  ReMVVMExt
//
//  Created by Dariusz Grzeszczak on 07/06/2019.
//

import ReMVVMCore
import UIKit

public struct NavigationStateIOS<ApplicationState>: NavigationState {

    public let navigation: Navigation

    public let appState: ApplicationState

    public var factory: ViewModelFactory {
        let factory: CompositeViewModelFactory
        if let f = navigation.factory as? CompositeViewModelFactory {
            factory = f
        } else {
            factory = CompositeViewModelFactory(with: navigation.factory)
        }

        return factory
    }

    public init(appState: ApplicationState,
                navigation: Navigation = Navigation(root: NavigationRoot(current: NavigationRoot.Main.single,
                                                                         stacks: [(NavigationRoot.Main.single, [])]),
                                                    modals: [])) {
        self.appState = appState
        self.navigation = navigation
    }
}

private enum AppNavigationReducer<State, R>: Reducer where R: Reducer, R.State == State, R.Action == StoreAction {

    static func reduce(state: NavigationStateIOS<State>, with action: StoreAction) -> NavigationStateIOS<State> {
        NavigationStateIOS<State>(
            appState: R.reduce(state: state.appState, with: action),
            navigation: NavigationReducer.reduce(state: state.navigation, with: action)
        )
    }
}

// todo rename to ReMVVM
public enum ReMVVMExtension {

    public static func initialize<ApplicationState, R>(with state: ApplicationState,
                                                    window: UIWindow,
                                                    uiStateConfig: UIStateConfig,
                                                    stateMappers: [StateMapper<ApplicationState>] = [],
                                                    reducer: R.Type,
                                                    middleware: [AnyMiddleware]) -> AnyStore where R: Reducer, R.State == ApplicationState, R.Action == StoreAction {

        let appMapper = StateMapper<NavigationStateIOS<ApplicationState>>(for: \.appState)
        let stateMappers = [appMapper] + stateMappers.map { $0.map(with: \.appState) }

        return self.initialize(with: NavigationStateIOS(appState: state),
                               window: window,
                               uiStateConfig: uiStateConfig,
                               stateMappers: stateMappers,
                               reducer: AppNavigationReducer<ApplicationState, R>.self,
                               middleware: middleware)
    }

    public static func initialize<State, R>(with state: State,
                                                          window: UIWindow,
                                                          uiStateConfig: UIStateConfig,
                                                          stateMappers: [StateMapper<State>] = [],
                                                          reducer: R.Type,
                                                          middleware: [AnyMiddleware]) -> AnyStore where State: NavigationState, R: Reducer, R.State == State, R.Action == StoreAction {

        let uiState = UIState(window: window, config: uiStateConfig)

        let middleware = [
            SynchronizeStateMiddleware<State>(uiState: uiState),
            ShowModalMiddleware<State>(uiState: uiState),
            DismissModalMiddleware<State>(uiState: uiState),
            ShowOnRootMiddleware<State>(uiState: uiState),
            ShowMiddleware<State>(uiState: uiState),
            PushMiddleware<State>(uiState: uiState),
            PopMiddleware<State>(uiState: uiState)
            ] + middleware

        let store = Store<State>(with: state,
                                 reducer: reducer,
                                 middleware: middleware,
                                 stateMappers: stateMappers)

        ReMVVM.initialize(with: store)
        return store.any
    }
}
