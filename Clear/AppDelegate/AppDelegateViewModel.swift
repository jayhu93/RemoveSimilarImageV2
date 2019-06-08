//
//  AppDelegateViewModel.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 3/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

protocol AppDelegateViewModelInputs {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    }

protocol AppDelegateViewModelOutputs {
      var setupUISignal: Signal<Void, NoError> { get }
}

protocol AppDelegateViewModelType {
    var inputs: AppDelegateViewModelInputs { get }
    var outputs: AppDelegateViewModelOutputs { get }
}

final class AppDelegateViewModel: AppDelegateViewModelType, AppDelegateViewModelInputs, AppDelegateViewModelOutputs {
    
    typealias Dependency = (
    )
    
    init(dependency: Dependency) {
 
        applicationDidFinishLaunchingReturnValueProperty = Property(value: true) // Always true for now
        applicationDidFinishLaunchingIO.output
            .observeValues { application, launchOptions in

        }
    }
    
    // MARK: AppDelegateViewModelType
    var inputs: AppDelegateViewModelInputs { return self }
    var outputs: AppDelegateViewModelOutputs { return self }
    
    // MARK: AppDelegateViewModelInputs
    private let applicationDidFinishLaunchingIO = Signal<(UIApplication, [UIApplication.LaunchOptionsKey: Any]?), NoError>.pipe()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        applicationDidFinishLaunchingIO.input.send(value: (application, launchOptions))
    }
    
    // MARK: AppDelegateViewModelOutputs
    private let applicationDidFinishLaunchingReturnValueProperty: Property<Bool>
    var setupUISignal: Signal<Void, NoError> { return applicationDidFinishLaunchingIO.output.map { _ in } }
}

