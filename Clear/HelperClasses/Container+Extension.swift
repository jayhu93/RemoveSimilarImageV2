//
//  Container+Extension.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 3/8/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import Swinject

extension Container {
    static let sharedResolver = Assembler([
        AppDelegateAssembly(),
        MainViewControllerAssembly(),
        SimilarImageServiceAssembly(),
        PhotoLibraryServiceAssembly(),
        SchedulerProviderAssembly(),
        LocalDatabaseAssembly(),
        ]).resolver
}

