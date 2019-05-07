//
//  SimilarImageServiceAssembly.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 3/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Swinject

final class SimilarImageServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(SimilarImageServiceType.self) { resolver in
            let dependency = (
            )
            return SimilarImageService(dependency: dependency)
            }.inObjectScope(.container)
        
        container.register(SimilarImageServiceOutputs.self) { resolver in
            resolver.resolve(SimilarImageServiceType.self)!.outputs
        }
        
        container.register(SimilarImageServiceInputs.self) { resolver in
            resolver.resolve(SimilarImageServiceType.self)!.inputs
        }
    }
}
