//
//  AppDelegateAssembly.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 3/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import Swinject

final class AppDelegateAssembly: Assembly {
    func assemble(container: Container) {
        container.register(AppDelegateViewModelType.self) { resolver in
            let dependency = (
            )
            return AppDelegateViewModel(dependency: dependency)
        }
    }
}

