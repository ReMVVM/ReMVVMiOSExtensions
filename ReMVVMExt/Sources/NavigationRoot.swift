//
//  StateTree.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak on 12/02/2019.
//  Copyright © 2019. All rights reserved.
//

import ReMVVM

public protocol NavigationState: StoreState {

    var navigationTree: Navigation { get }
}

public protocol NavigationElement: Hashable {
    static var controllerType: UIViewController.Type { get }
    static var viewModelType: Any.Type { get }
}

public struct AnyNavigationElement: NavigationElement {
    public static var viewModelType: Any.Type { fatalError()  }
    public static var controllerType: UIViewController.Type { fatalError() }


}

public enum Navigation: Equatable {
    case root
    case custom(AnyNavigationElement)
}

public protocol CustNav {
    associatedtype N: NavigationElement

    var current: N { get }
    var stacks: [N: [ViewModelFactory]] { get }
}


public struct CustomNavigation<N: NavigationElement>: CustNav {
    public let current: N
    public let stacks: [N : [ViewModelFactory]]
}

public enum NavigationLeaf {
    case stack([ViewModelFactory])
    case custom(Int, [[ViewModelFactory]])
}

public struct NavigationD: Hashable {
    public static func == (lhs: NavigationD, rhs: NavigationD) -> Bool {
        return lhs.variant == rhs.variant
    }

    public let variant: AnyHashable
    public let variantType: Any.Type


    public init<V>(variant: V) where V: Hashable{
        variantType = type(of: variant)
        self.variant = AnyHashable(variant)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(variant)
    }
}

enum NavigationT {
    case flat(stack: [ViewModelFactory])
    case tree(d: Int)
}

public struct NavigationTree {
    let current: AnyNavigationTab
    let stacks: [(AnyNavigationTab, [ViewModelFactory])]

    var stack: [ViewModelFactory] { stacks.first { $0.0 == current }?.1 ?? [] }

    static let root = Root.flat

//    public init(stack: [ViewModelFactory]) {
//        current = NavigationD(variant: Empty.zero)
//        self.stacks = [current: stack]
//    }

    public init(current: AnyNavigationTab, stacks: [(AnyNavigationTab, [ViewModelFactory])]) {
        self.current = current
        self.stacks = stacks
    }

    public init<T>(current: T, stacks: [(T, [ViewModelFactory])]) where T: NavigationTab {
        self.current = AnyNavigationTab(current)
        self.stacks = stacks.map { (AnyNavigationTab($0),$1)}
    }

//    func get<T>() -> (T, [T: [ViewModelFactory] ])? where T: Hashable {
//        guard let current = self.current as? T else { return nil }
//        let stacks: [T: [ViewModelFactory]] = self.stacks.reduce(into: [:]) { d, i in
//            guard let key = i.key as? T else { return }
//            d[key] = i.value
//        }
//        return (current, stacks)
//    }

    public enum Root: NavigationTab {
        //TODO

        public var action: StoreAction { FakeAction() }

        case flat


        private struct FakeAction: StoreAction {}
    }
}

public struct Navigation {

    public let modals: [Modal]
    public let tree: NavigationTree

    public init(tree: NavigationTree, modals: [Modal]) {
        self.tree = tree
        self.modals = modals
    }

    public var factory: ViewModelFactory {
        return modals.last?.factory ?? tree.stack.last ?? CompositeViewModelFactory()
    }

    public enum Modal {
        case single(ViewModelFactory)
        case navigation([ViewModelFactory])

        public var factory: ViewModelFactory? {
            switch self {
            case .single(let factory): return factory
            case .navigation(let stack): return stack.last
            }
        }

        public var hasNavigation: Bool {
            guard case .navigation = self else { return false }
            return true
        }
    }

    public var topStack: [ViewModelFactory] {
        if let modal = modals.last {
            guard case .navigation(let stack) = modal else { return [] }
            return stack
        } else {
            return tree.stack
        }
    }
}

public enum NavigationTreeReducer {

    public static func reduce(state: Navigation, with action: StoreAction) -> Navigation {
        let reducers: [ AnyReducer<Navigation>] = [
                        ShowOnRootReducer.any,
                        ShowOnTabReducer.any,
                        SynchronizeStateReducer.any,
                        PushReducer.any,
                        PopReducer.any,
                        ShowModalReducer.any,
                        DismissModalReducer.any]

        return AnyReducer(with: reducers).reduce(state: state, with: action)
    }
}
