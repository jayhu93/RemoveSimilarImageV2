//
//  MainPhotoViewModel.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/11/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import ReactiveSwift
import Result

protocol MainPhotoViewModelInputs {

}

protocol MainPhotoViewModelOutputs {

}

protocol MainPhotoViewModelType {
    var outputs: MainPhotoViewModelOutputs { get }
    var inputs: MainPhotoViewModelInputs { get }
}

final class MainPhotoViewModel: MainPhotoViewModelType, MainPhotoViewModelInputs, MainPhotoViewModelOutputs {
    
    typealias Dependency = (

    )
    
    init(dependency: Dependency) {

    }
    
    // MARK: - MainPhotoViewModelType
    
    var inputs: MainPhotoViewModelInputs { return self }
    var outputs: MainPhotoViewModelOutputs { return self }
    
    // MARK: - MainPhotoViewModelInputs

    // MARK: - MainPhotoViewModelOutputs

}
