//
//  ViewModelProvided.swift
//  ReMVVMExt
//
//  Created by Dariusz Grzeszczak on 10/10/2019.
//

import Loaders
import ReMVVMCore

@propertyWrapper
public struct ViewModelProvided<VMD> where VMD: ViewModelDriven {

    public var wrappedValue: VMD? {
        didSet {
            guard   let responder = wrappedValue,
                    let viewModel = viewModel.wrappedValue
            else { return }
            responder.viewModel = viewModel
        }
    }

    private var viewModel: ReMVVM.ViewModel<VMD.ViewModelType>
    public init() {
        viewModel = ReMVVM.ViewModel()
    }
    public init(key: String) {
        viewModel = ReMVVM.ViewModel(key: key)
    }
}
