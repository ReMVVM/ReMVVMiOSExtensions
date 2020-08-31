//
//  SynchronizeStateReducer.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019. All rights reserved.
//

import Foundation
import ReMVVM
import RxSwift
import RxCocoa
import UIKit

// needed to synchronize the state when user use back button or swipe gesture
struct SynchronizeStateReducer: Reducer {

    public typealias Action = SynchronizeState

    public static func reduce(state: NavigationTree, with action: SynchronizeState) -> NavigationTree {
        if action.type == .navigation {
            return PopReducer.reduce(state: state, with: Pop())
        } else {
            return DismissModalReducer.reduce(state: state, with: DismissModal())
        }
    }
}

public final class SynchronizeStateMiddleware: AnyMiddleware {
    public let uiState: UIState

    public init(uiState: UIState) {
        self.uiState = uiState
    }

    private var disposeBag = DisposeBag()

    public func onNext<State>(for state: State,
                            action: StoreAction,
                            interceptor: Interceptor<StoreAction, State>,
                            dispatcher: Dispatcher) where State: StoreState {

        guard let state = state as? NavigationTreeContainingState else {
            interceptor.next()
            return
        }

        if let action = action as? SynchronizeState {

            if  action.type == .navigation,
                let navigationCount = uiState.navigationController?.viewControllers.count,
                state.navigationTree.topStack.count > navigationCount {

                interceptor.next()
            } else if action.type == .modal, uiState.modalControllers.last?.isBeingDismissed == true {
                uiState.modalControllers.removeLast()
                interceptor.next()
            }
        } else {
            interceptor.next { [weak self] _ in
                let disposeBag = DisposeBag()
                self?.disposeBag = disposeBag
                self?.uiState.navigationController?.rx.didShow
                    .subscribe(onNext: { con in
                        print(con.viewController)
                        dispatcher.dispatch(action: SynchronizeState(.navigation))
                    })
                    .disposed(by: disposeBag)

                guard let modal = self?.uiState.modalControllers.last else { return }

                modal.rx.viewDidDisappear
                    .subscribe(onNext: { _ in
                        dispatcher.dispatch(action: SynchronizeState(.modal))
                    })
                    .disposed(by: disposeBag)
            }
        }
    }
}


private extension Reactive where Base: UIViewController {

  var viewDidDisappear: ControlEvent<Bool> {
    let source = self.methodInvoked(#selector(Base.viewDidDisappear)).map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }
}
