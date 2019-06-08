//
//  SchedulerProviderAssembly.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/23/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Swinject

final class SchedulerProviderAssembly: Assembly {
    func assemble(container: Container) {
        container.register(SchedulerProviderType.self) { _ in SchedulerProvider.shared }
    }
}
