//
//  MainViewControllerAssembly.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 3/8/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Swinject
import UIKit

final class MainViewControllerAssembly: Assembly {
    func assemble(container: Container) {
        container.register(MainViewModel.self) { resolver in
            let dependency = (
                resolver.resolve(SimilarImageServiceType.self)!,
                resolver.resolve(PhotoLibraryServiceType.self)!,
                resolver.resolve(LocalDatabaseType.self)!
            )
            return MainViewModel(dependency: dependency)
        }
        container.register(MainViewController.self) { resolver in
            let vc = UIStoryboard.instantiateViewController(of: MainViewController.self)
            vc.viewModel = resolver.resolve(MainViewModel.self)
            return vc
        }
        container.register(MainPhotoViewModelType.self) { resolver in
            let dependency = (

            )
            return MainPhotoViewModel(dependency: dependency)
        }
    }
}

extension MainViewController {
    static func make() -> MainViewController {
        return Container.sharedResolver.resolve(MainViewController.self)!
    }
}
