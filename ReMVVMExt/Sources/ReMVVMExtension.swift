//
//  ReMVVMExtension.swift
//  ReMVVMExt
//
//  Created by Dariusz Grzeszczak on 07/06/2019.
//

import ReMVVM
import RxSwift
import UIKit

//TODO mappers based on appstate
public struct ReMVVMiOSState<AppState>: NavigationState {

    public let navigation: Navigation

    public let appState: AppState

    public var factory: ViewModelFactory {
        let factory: CompositeViewModelFactory
        if let f = navigation.factory as? CompositeViewModelFactory {
            factory = f
        } else {
            factory = CompositeViewModelFactory(with: navigation.factory)
        }

        return factory
    }

    public init(appState: AppState,
                navigation: Navigation = Navigation(root: NavigationRoot(current: NavigationRoot.Main.single, stacks: [(NavigationRoot.Main.single, [])]), modals: [])) {

        self.appState = appState
        self.navigation = navigation
    }
}

//public func onNext<State: StoreState>(for state: State, action: StoreAction, interceptor: Interceptor<StoreAction, State>, dispatcher: Dispatcher) {
//    guard   let action = action as? Self.Action,
//            let state = state as? Self.State,
//            let inter = interceptor as? Interceptor<StoreAction, Self.State>
//    else {
//        interceptor.next()
//        return
//    }
//
//    let interceptor = Interceptor<Self.Action, Self.State> { act, completion in
//        inter.next(action: act ?? action, completion: completion)
//    }
//    onNext(for: state, action: action, interceptor: interceptor, dispatcher: dispatcher)
//}

//struct ReMVVMiOSSMiddleware<St>: AnyMiddleware {
//
//    let middleware: AnyMiddleware
//
//    func onNext<State>(for state: State, action: StoreAction, interceptor: Interceptor<StoreAction, State>, dispatcher: Dispatcher) where State : StoreState {
//
//        guard   let state = state as? ReMVVMiOSState<St>,
//                let inter = interceptor as? InterceptorStoreAction, ReMVVMiOSState<St>>
//        else {
//            interceptor.next()
//        }
//
//        let interceptor = Interceptor<StoreAction, St> { act, completion in
//
//        }
//
//    }
//}

public enum ReMVVMExtension {

//    public static func initializeWithReMVVMiOSState<State>(with window: UIWindow,
//                                                     uiStateConfig: UIStateConfig,
//                                                     state: State,
//                                                     stateMappers: [StateMapper<State>] = [],
//                                                     reducer: AnyReducer<State>,
//                                                     middleware: [AnyMiddleware]) -> Store<ReMVVMiOSState<State>> {
//
//        let rdr = AnyReducer { state, action -> ReMVVMiOSState<State> in
//            return ReMVVMiOSState<State>(
//                appState: reducer.reduce(state: state.appState, with: action),
//                navigationTree: NavigationTreeReducer.reduce(state: state.navigationTree, with: action)
//            )
//        }
//
//        let mid = middleware.map { midleware in
//
//            AnyMiddleware
//
//        }
//
//        return self.initialize(with: window,
//                               uiStateConfig: uiStateConfig,
//                               state: ReMVVMiOSState(appState: state),
//                               reducer: rdr,
//                               middleware: [])
//    }

    public static func initialize<State: StoreState>(with window: UIWindow,
                                                     uiStateConfig: UIStateConfig,
                                                     state: State,
                                                     stateMappers: [StateMapper<State>] = [],
                                                     reducer: AnyReducer<State>,
                                                     middleware: [AnyMiddleware]) -> Store<State> {

        let uiState = UIState(window: window, config: uiStateConfig)

        let middleware: [AnyMiddleware] = [
            SynchronizeStateMiddleware(uiState: uiState),
            ShowModalMiddleware(uiState: uiState),
            DismissModalMiddleware(uiState: uiState),
            ShowOnRootMiddleware(uiState: uiState),
            ShowMiddleware(uiState: uiState),
            PushMiddleware(uiState: uiState),
            PopMiddleware(uiState: uiState)
            ] + middleware

        let store = Store<State>(with: state,
                                 reducer: reducer,
                                 middleware: middleware,
                                 stateMappers: stateMappers)

        store.add(observer: EndEditingFormListener<State>(uiState: uiState))
        ReMVVM.initialize(with: store)
        return store
    }
}

public final class EndEditingFormListener<State: StoreState>: StateObserver {

    let uiState: UIState
    var disposeBag = DisposeBag()

    public init(uiState: UIState) {
        self.uiState = uiState
    }

    public func willChange(state: State) {
        uiState.rootViewController.view.endEditing(true)
        uiState.modalControllers.last?.view.endEditing(true)
    }

    public func didChange(state: State, oldState: State?) {
        disposeBag = DisposeBag()

        uiState.navigationController?.rx
            .methodInvoked(#selector(UINavigationController.popViewController(animated:)))
            .subscribe(onNext: { [unowned self] _ in
                self.uiState.rootViewController.view.endEditing(true)
                self.uiState.modalControllers.last?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
    }
}
