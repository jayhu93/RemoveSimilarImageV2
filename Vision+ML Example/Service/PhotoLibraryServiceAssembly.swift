//
//  PhotoLibraryServiceAssembly.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/23/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Swinject

final class PhotoLibraryServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(PhotoLibraryServiceType.self) { resolver in
            let dependency = (
                resolver.resolve(SchedulerProviderType.self)!,
                resolver.resolve(SimilarImageServiceType.self)!,
                resolver.resolve(LocalDatabaseType.self)!
            )
            return PhotoLibraryService(dependency: dependency)
            }.inObjectScope(.container)

        container.register(PhotoLibraryServiceOutputs.self) { resolver in
            resolver.resolve(PhotoLibraryServiceType.self)!.outputs
        }

        container.register(PhotoLibraryServiceInputs.self) { resolver in
            resolver.resolve(PhotoLibraryServiceType.self)!.inputs
        }
    }
}
