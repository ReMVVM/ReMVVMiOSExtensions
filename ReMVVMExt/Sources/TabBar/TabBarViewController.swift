//
//  TabBarViewController.swift
//  BNCommon
//
//  Created by Grzegorz Jurzak on 12/02/2019.
//  Copyright © 2019 HYD. All rights reserved.
//

import Loaders
import ReMVVM
import RxCocoa
import RxSwift
import UIKit

public typealias UITabBarItemConfig<T> = (_ tabBar: UITabBar, _ items: [ItemWithTabBarItem<T>]) -> HeightWithOverlay where T: NavigationItem

public typealias CustomTabBarItemConfig<T> = (_ tabBar: UITabBar, _ items: [T]) -> CustomReturn where T: NavigationItem

public typealias CustomConfig<T> = (_ items: [T]) -> NavigationContainerController where T: NavigationItem

public struct NavigationConfig {

    public enum ConfigError: Error {
        case toManyElements
    }

    public init<T>(_ creator: @escaping UITabBarItemConfig<T>, for type: T.Type = T.self) throws where T: CaseIterableNavigationItem {
        guard T.allCases.count <= 5 else { throw ConfigError.toManyElements }

        navigationType = T.navigationType
        config = .uiTabBar { tabBar, items in
            return creator(tabBar, items.compactMap {
                guard let item = $0.item.base as? T else { return nil }
                return ItemWithTabBarItem<T>(item: item, uiTabBarItem: $0.uiTabBarItem)
            })
        }
    }

    public init<T>(_ creator: @escaping CustomTabBarItemConfig<T>, for type: T.Type = T.self) where T: CaseIterableNavigationItem {

        navigationType = T.navigationType
        config = .customTabBar { tabBar, items in
            creator(tabBar, items.compactMap { $0.base as? T })
        }
    }

    public init<T>(_ creator: @escaping CustomConfig<T>, for type: T.Type = T.self) where T: CaseIterableNavigationItem {

        navigationType = T.navigationType
        config = .custom { items in
            return creator(items.compactMap {$0.base as? T})
        }
    }

    let navigationType: NavigationType
    let config: Config<AnyNavigationItem>
    enum Config<T> where T: NavigationItem {

        case uiTabBar(UITabBarItemConfig<T>)
        case customTabBar(CustomTabBarItemConfig<T>)
        case custom(CustomConfig<T>)
    }
}

public struct ItemWithTabBarItem<T> {
    public let item: T
    public let uiTabBarItem: UITabBarItem
}

public struct HeightWithOverlay {
    public let height: CGFloat?
    public let overlay: UIView?

    public init(height: CGFloat? = nil, overlay: UIView? = nil) {
        self.height = height
        self.overlay = overlay
    }
}

public struct CustomReturn {
    public let height: CGFloat?
    public let overelay: UIView
    public let controls: [UIControl]

    public init(height: CGFloat? = nil, overelay: UIView, controls: [UIControl]) {
        self.height = height
        self.overelay = overelay
        self.controls = controls
    }
}

//public struct TabBarConfig {
//
//    enum ConfigError: Error {
//        case toManyElements
//    }
//
//    let height: CGFloat?
//    let configureItems: ItemsConfigurator<AnyNavigationItem>?
//    let configureTabBar: ((UITabBar) -> Void)?
//
//    let all: [AnyNavigationItem]
//
//    public init<Tab>(height: CGFloat? = nil,
//                     configureTabBar: ((UITabBar) -> Void)? = nil,
//                     configureItems: ItemsConfigurator<Tab>? = nil,
//                     tabType: Tab.Type = Tab.self) throws where Tab: CaseIterableNavigationItem {
//        self.height = height
//        self.configureTabBar = configureTabBar
//        self.configureItems = configureItems?.any
//        all = Tab.allCases.any
//
//        if case .custom = configureItems { return }
//        else if all.count > 5 {
//            throw ConfigError.toManyElements
//        }
//    }
//
//    public  enum ItemsConfigurator<Tab> {
//        case uiTabBar(([(Tab, UITabBarItem)]) -> UIView?)
//        case custom(([Tab]) -> (UIView, [UIControl]))
//
//        var any: ItemsConfigurator<AnyNavigationItem> {
//            switch self {
//            case .uiTabBar(let creator):
//                return .uiTabBar { creator($0.map { ($0.0.base as! Tab, $0.1) }) }
//            case .custom(let creator):
//                return .custom { creator($0.map { $0.base as! Tab }) }
//            }
//        }
//    }
//}

private class TabBar: UITabBar {

    var customView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let customView = customView else { return }
            customView.frame = bounds
            addSubview(customView)
        }
    }

    var controlItems: [UIControl]?

    var height: CGFloat? {
        didSet {
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        customView?.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setItems(_ items: [UITabBarItem]?, animated: Bool) {

        super.setItems(items, animated: animated)
        guard controlItems != nil else { return }
        subviews
            .compactMap { $0 as? UIControl }
            .filter { $0 != customView }
            .forEach { $0.removeFromSuperview() }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        if let height = height {
            size.height = height
        }
        return size
    }

    var _selectedItem: UITabBarItem? {
        didSet {
            if  _selectedItem != oldValue,
                let tabBarItem = _selectedItem as? TabBarItem,
                let control = tabBarItem.controlItem {

                controlItems?.forEach {
                    $0.isSelected = $0 == control
                }
            }
        }
    }

    override var selectedItem: UITabBarItem? {
        set {
            super.selectedItem = newValue
            _selectedItem = newValue
        }

        get {
            _selectedItem
        }
    }
}

class TabBarItem: UITabBarItem {

    let navigationTab: AnyNavigationItem
    let controlItem: UIControl?

    init(navigationTab: AnyNavigationItem, controlItem: UIControl?) {
        self.navigationTab = navigationTab
        self.controlItem = controlItem
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContainerViewController: UIViewController {
    let currentNavigationController: UINavigationController?

    init() {
        let topNavigation = UINavigationController()
        self.currentNavigationController = topNavigation
        super.init(nibName: nil, bundle: nil)

        topNavigation.willMove(toParent: self)
        addChild(topNavigation)
        view.addSubview(topNavigation.view)
        topNavigation.didMove(toParent: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class TabBarViewController: UITabBarController, NavigationContainerController, ReMVVMDriven {
    init(config: NavigationConfig?) {
        self.config = config

        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var containers: [ContainerViewController]? {
        viewControllers?.compactMap { $0 as? ContainerViewController }
    }

    public var currentNavigationController: UINavigationController? {
        guard selectedIndex >= 0 && selectedIndex < containers?.count ?? 0 else { return nil }
        return containers?[selectedIndex].currentNavigationController
    }

    private var config: NavigationConfig?

    @Provided private var viewModel: NavigationViewModel<AnyNavigationItem>?

    override open var childForStatusBarStyle: UIViewController? {
        return currentNavigationController?.topViewController
    }

    private var customTabBar: TabBar { return tabBar as! TabBar}

//    private var moreDelegate: UITableViewDelegate?
    open override func viewDidLoad() {
        setValue(TabBar(), forKey: "tabBar")
        super.viewDidLoad()

        delegate = self
        guard let viewModel = viewModel else { return }

        viewModel.items.subscribe(onNext: { [unowned self] items in
            self.setup(items: items)
        }).disposed(by: disposeBag)

        viewModel.selected.subscribe(onNext: { [unowned self] item in
            self.setup(current: item)
        }).disposed(by: disposeBag)
    }

    private let disposeBag = DisposeBag()
    private func setup(items: [AnyNavigationItem]) {

        let tabItems: [UITabBarItem]
        if case let .customTabBar(configurator) = config?.config {

            let result = configurator(customTabBar, items)
            customTabBar.height = result.height
            let customView = result.overelay
            let controlItems = result.controls

            controlItems.enumerated().forEach { index, elem in
                elem.rx.controlEvent(.touchUpInside).subscribe(onNext: { [unowned self] in
                    if let viewController = self.viewControllers?[index] {
                        self.sendAction(for: viewController)
                    }
                }).disposed(by: disposeBag)
            }

            tabItems = zip(items, controlItems).map {
                TabBarItem(navigationTab: $0, controlItem: $1)
            }

            customTabBar.customView = customView
            customTabBar.controlItems = controlItems

            moreNavigationController.navigationBar.isHidden = true

        } else {
            let tabBarItems: [TabBarItem] = items.map { TabBarItem(navigationTab: $0, controlItem: nil) }

            tabItems = tabBarItems

            if case let .uiTabBar(configurator) = config?.config {
                let result = configurator(customTabBar, tabBarItems.map { ItemWithTabBarItem(item: $0.navigationTab, uiTabBarItem: $0) })
                customTabBar.customView = result.overlay
                customTabBar.controlItems = nil
                customTabBar.height = result.height
            } else {
                customTabBar.customView = nil
                customTabBar.controlItems = nil
                customTabBar.height = nil
            }

            moreNavigationController.navigationBar.isHidden = false
        }

        viewControllers = tabItems.map { tab in
            let controller = ContainerViewController()
            controller.tabBarItem = tab
            return controller
        }
    }
    
    private func setup(current: AnyNavigationItem) {

        let selected = viewControllers?.first {
            guard let tab = $0.tabBarItem as? TabBarItem else { return false }
            return current == tab.navigationTab
        }

        guard selected != nil else { return }
        selectedViewController = selected
        customTabBar._selectedItem = selectedViewController?.tabBarItem
    }

    private func sendAction(for viewController: UIViewController) {
        guard let tab = viewController.tabBarItem as? TabBarItem else { return }
        remvvm.dispatch(action: tab.navigationTab.action)
    }

}

extension TabBarViewController: UITabBarControllerDelegate {

    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        DispatchQueue.main.async {
            self.sendAction(for: viewController)
        }
        return false
    }
}

