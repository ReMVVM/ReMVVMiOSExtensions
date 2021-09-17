//
//  TabBarViewModel.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak on 12/02/2019.
//  Copyright © 2019 HYD. All rights reserved.
//

import Foundation
import ReMVVMCore

@propertyWrapper
public final class ObservableValue<T> {

    public typealias Observer = (T) -> Void

    public var wrappedValue: T {
        didSet {
            projectedValue?(wrappedValue)
        }
    }

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public var projectedValue: Observer?
}

open class NavigationViewModel<Item: NavigationItem>: Initializable, StateObserver {

    @ObservableValue public var items: [Item] = []
    @ObservableValue public var selected: Item?

    required public init() { }

    public func didReduce(state: NavigationState, oldState: NavigationState?) {
        if Item.self == AnyNavigationItem.self {
            let tabType = type(of: state.navigation.root.currentItem.base)
            let items = state.navigation.root.stacks.map { $0.0 }
                .filter { type(of: $0.base) == tabType }
                .compactMap { $0 as? Item }

            if items.count != 0 && items != self.items {
                self.items = items
            }

            let selected = state.navigation.root.currentItem as? Item
            if selected != nil && selected != self.selected {
                self.selected = selected
            }
        } else {
            let items = state.navigation.root.stacks.compactMap { $0.0.base as? Item }
            if items.count != 0 && items != self.items {
                self.items = items
            }

            let selected =  state.navigation.root.currentItem.base as? Item
            if selected != nil && selected != self.selected {
                self.selected = selected
            }
       }
    }
}

public typealias CaseIterableNavigationItem = NavigationItem & CaseIterable

public protocol NavigationItem: Hashable {
    var action: StoreAction { get }
}

public struct AnyNavigationItem: NavigationItem {

    public let action: StoreAction

    let base: Any

    public init<T: NavigationItem>(_ tab: T) {

        action = tab.action

        base = tab

        isEqual = { t in
            guard let t = t.base as? T else { return false }
            return tab == t
        }

        _hash = { hasher in
            tab.hash(into: &hasher)
        }
    }

    public func hash(into hasher: inout Hasher) {
        _hash(&hasher)
    }

    private var isEqual: (AnyNavigationItem) -> Bool
    private var _hash: (inout Hasher) -> Void

    public static func == (lhs: AnyNavigationItem, rhs: AnyNavigationItem) -> Bool {
        lhs.isEqual(rhs)
    }

}

extension NavigationItem {

    public var any: AnyNavigationItem {
        return AnyNavigationItem(self)
    }
}

extension Collection where Element: NavigationItem {
    public var any: [AnyNavigationItem] {
        return map { $0.any }
    }
}
