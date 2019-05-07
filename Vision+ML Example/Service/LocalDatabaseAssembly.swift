//
//  LocalDatabaseAssembly.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 5/1/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import Swinject

final class LocalDatabaseAssembly: Assembly {
    func assemble(container: Container) {
        container.register(LocalDatabaseType.self) { resolver in
            let dependency = (
            )
            return LocalDatabase(dependency: dependency)
            }.inObjectScope(.container)

        container.register(LocalDatabaseOutputs.self) { resolver in
            resolver.resolve(LocalDatabaseType.self)!.outputs
        }

        container.register(LocalDatabaseInputs.self) { resolver in
            resolver.resolve(LocalDatabaseType.self)!.inputs
        }
    }
}
