//
//  TabBarViewModel.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak on 12/02/2019.
//  Copyright © 2019 HYD. All rights reserved.
//

import Foundation
import ReMVVM
import RxSwift

public final class TabBarViewModel: Initializable, StateObserver, ReMVVMDriven {
    public typealias State = NavigationTabState

    public let tabBarItemsViewModels: Observable<[TabBarItemViewModel]>

    public init() {
        tabBarItemsViewModels = TabBarViewModel.remvvm.stateSubject.rx.state
            .map { $0.currentTab }
            .distinctUntilChanged()
            .withLatestFrom(TabBarViewModel.remvvm.stateSubject.rx.state, resultSelector: { current, state -> [TabBarItemViewModel] in
                return type(of: state).allTabs.map {
                    TabBarItemViewModel(tab: $0, isSelected: $0 == current)
                }
            })
    }
}

public protocol NavigationTabState: StoreState {
    var currentTab: AnyNavigationTab? { get }
    static var allTabs: [AnyNavigationTab] { get }
}

public struct AnyNavigationTab: NavigationTab {

    public let title: String
    public let iconImage: Data
    public let iconImageActive: Data
    public let action: StoreAction
    public let tintable: Bool
}

public protocol NavigationTab: Equatable {
    var title: String { get }
    var iconImage: Data { get }
    var iconImageActive: Data { get }
    var action: StoreAction { get }
    var tintable: Bool { get }
}

extension NavigationTab {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.title == rhs.title
    }

    public var any: AnyNavigationTab {
        return AnyNavigationTab(title: title,
                                iconImage: iconImage,
                                iconImageActive: iconImageActive,
                                action: action,
                                tintable: tintable)
    }
}

extension Array where Element: NavigationTab {
    public var any: [AnyNavigationTab] {
        return map { $0.any }
    }
}
