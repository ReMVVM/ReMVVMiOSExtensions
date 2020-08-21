//
//  TabBarItemViewModel.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak on 13/02/2019.
//  Copyright © 2019 HYD. All rights reserved.
//

import Foundation
import RxSwift
import ReMVVM

public struct TabBarItemViewModel {

    public let title: Observable<String>

    public let iconImage: Observable<Data>
    public let iconImageActive: Observable<Data>

    public let isSelected: Observable<Bool>

    public let action: Observable<StoreAction>
    public var tintColor: Observable<UIColor> {
        return self.isSelected.compactMap { $0 ? tab.activeTintColor : tab.inactiveTintColor }
    }

    public init<Tab: NavigationTab>(tab: Tab, isSelected: Bool) {
        title = .just(tab.title)
        iconImage = .just(tab.iconImage)
        iconImageActive = .just(tab.iconImageActive)
        self.isSelected = .just(isSelected)
        action = .just(tab.action)
    }
}
