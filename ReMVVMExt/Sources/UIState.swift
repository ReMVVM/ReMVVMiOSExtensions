//
//  UIState.swift
//  ReMVVMExt
//
//  Created by Grzegorz Jurzak, Daniel Plachta, Dariusz Grzeszczak.
//  Copyright © 2019 HYD. All rights reserved.
//

import UIKit
import Loaders

public struct UIStateConfig {
    let initialController: () -> UIViewController
    let navigationController: () -> ReMVVMNavigationController
    let navigationConfigs: [NavigationConfig]
    let navigationBarHidden: Bool

    public init(initialController: @escaping @autoclosure () -> UIViewController,
                navigationController: (() -> ReMVVMNavigationController)? = nil,
                navigationConfigs: [NavigationConfig] = [],
                navigationBarHidden: Bool = true) {
        self.initialController = initialController
        self.navigationController = navigationController ?? { ReMVVMNavigationController() }
        self.navigationConfigs = navigationConfigs
        self.navigationBarHidden = navigationBarHidden
    }
}

public protocol NavigationContainerController where Self: UIViewController {
    var currentNavigationController: UINavigationController? { get }
    var containers: [ContainerViewController]? { get }
}

public final class UIState {
    private let window: UIWindow
    private let uiStateMainController: UINavigationController

    public internal(set) var modalControllers: [UIViewController] = []

    public let config: UIStateConfig

    public init(window: UIWindow, config: UIStateConfig) {
        self.window = window
        self.config = config

        uiStateMainController = config.navigationController()
        uiStateMainController.view.bounds = window.bounds
        uiStateMainController.setNavigationBarHidden(config.navigationBarHidden, animated: false)

        window.rootViewController = uiStateMainController

        setRoot(controller: config.initialController(),
                animated: false,
                navigationBarHidden: config.navigationBarHidden) { }
    }

    public func setRoot(controller: UIViewController,
                        animated: Bool,
                        navigationBarHidden: Bool,
                        completion: @escaping () -> Void) {
        if uiStateMainController.isNavigationBarHidden != navigationBarHidden {
            uiStateMainController.setNavigationBarHidden(navigationBarHidden, animated: animated)
        }
        uiStateMainController.setViewControllers([controller],
                                                 animated: animated,
                                                 completion: completion)
    }

    public var rootViewController: UIViewController {
        uiStateMainController.viewControllers[0]
    }

    public var navigationController: UINavigationController? {
        modalControllers
            .compactMap { $0 as? UINavigationController }
            .last ?? (rootViewController as? NavigationContainerController)?
            .currentNavigationController ?? uiStateMainController
    }

    private var topPresenter: UIViewController {
        modalControllers.last ?? rootViewController
    }

    public func present(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        topPresenter.present(viewController, animated: animated) { [topPresenter] in
            topPresenter.setNeedsStatusBarAppearanceUpdate()
            completion()
        }
        modalControllers.append(viewController)
    }

    public func dismissAll(animated: Bool, completion: @escaping () -> Void) {
        dismiss(animated: animated, number: Int.max, completion: completion)
    }

    public func dismiss(animated: Bool, number: Int = 1, completion: @escaping () -> Void) {
        let number = modalControllers.count >= number ? number : modalControllers.count
        guard number > 0 else {
            completion()
            return
        }
        modalControllers.removeLast(number)
        topPresenter.dismiss(animated: animated) { [topPresenter] in
            topPresenter.setNeedsStatusBarAppearanceUpdate()
            completion()
        }
    }
}
