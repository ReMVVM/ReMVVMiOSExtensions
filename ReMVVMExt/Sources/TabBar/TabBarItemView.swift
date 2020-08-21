//
//  TabBarItemView.swift
//  BNUICommon
//
//  Created by Grzegorz Jurzak on 13/02/2019.
//  Copyright © 2019 HYD. All rights reserved.
//

import Loaders
import ReMVVM
import RxCocoa
import RxSwift
import UIKit

open class TabBarItemView: UIView, ReMVVMDriven {

    var viewModel: TabBarItemViewModel? {
        didSet {
            guard let viewModel = self.viewModel else { return }
            bind(viewModel)
        }
    }

    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var iconImageView: UIImageView!
    fileprivate var tapGesture: UITapGestureRecognizer?

    public let disposeBag = DisposeBag()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupNib()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNib()
    }

    open func selectionChanged(isSelected: Bool) {}

    open func setupNib() {
        Nib.add(to: self)
    }

    open func bind(_ viewModel: TabBarItemViewModel) {
        viewModel.title.bind(to: titleLabel.rx.text).disposed(by: disposeBag)
        Observable.combineLatest(viewModel.isSelected, viewModel.iconImage, viewModel.iconImageActive)
            .map { $0.0 ? $0.2 : $0.1 }
            .map { UIImage(data: $0) }
            .bind(to: iconImageView.rx.image)
            .disposed(by: disposeBag)
        viewModel.tintColor
            .subscribe(next: { [iconImageView] color in iconImageView?.tintColor = color })
            .disposed(by: disposeBag)
        rx.tap
            .skipUntil(viewModel.isSelected)
            .withLatestFrom(viewModel.action)
            .bind(to: remvvm.rx)
            .disposed(by: disposeBag)
        viewModel.isSelected.subscribe(onNext: selectionChanged).disposed(by: disposeBag)
    }
}

private extension Reactive where Base: TabBarItemView {

    var tap: ControlEvent<Void> {
        var tapGesture: UITapGestureRecognizer

        if let gesture = base.tapGesture {
            tapGesture = gesture
        } else {
            tapGesture = UITapGestureRecognizer()
            base.addGestureRecognizer(tapGesture)
            base.tapGesture = tapGesture
        }

        return ControlEvent(events: tapGesture.rx.event.map { _ in return })
    }
}
