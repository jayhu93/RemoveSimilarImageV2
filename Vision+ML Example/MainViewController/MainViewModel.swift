//
//  MainViewModel.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 3/8/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import ReactiveSwift
import UIKit
import Result

protocol MainViewModelInputs {
    func viewDidLoad()
    func removeAllObjs()
    func printSimilarPhotoObjects()
}

protocol MainViewModelOutpus {
    func numberOfSections() -> Int
    func numberOfElements(_ section: Int) -> Int
}

protocol MainViewModelType {
    var inputs: MainViewModelInputs { get }
    var outputs: MainViewModelOutpus { get }
}

final class MainViewModel: MainViewModelType, MainViewModelInputs, MainViewModelOutpus {
    
    typealias Dependency = (
        SimilarImageServiceType,
        PhotoLibraryServiceType,
        LocalDatabaseType
    )
    
    init(dependency: Dependency) {
        let (similarImageService, photoLibraryService, localDatabase) = dependency
        print("got similar image service: \(similarImageService)")

        similarImageService.outputs.similarImageResultSignal.observeValues { photoResult in
            let photoObject = PhotoObject()
            photoObject.id = photoResult.rawPhoto.id
            let similarArray = photoResult.results.map { $0.offset }
            photoObject.similarArray.append(objectsIn: similarArray)
            localDatabase.inputs.addPhotoObject(photoObject)
        }

        photoLibraryService.outputs.photoSignal.observeValues { rawPhoto in
            similarImageService.inputs.analyze(rawPhoto: rawPhoto)
        }
        
        viewDidLoadIO.output.observeValues {
            photoLibraryService.inputs.fetchImage()
        }

        removeAllObjcsIO.output.observeValues {
            localDatabase.inputs.deleteAllObjects()
        }

        printSimilarPhotoObjectsIO.output.observeValues {
            localDatabase.inputs.returnSomeResults()
        }
    }
    
    var inputs: MainViewModelInputs { return self }
    var outputs: MainViewModelOutpus { return self }
    
    private let viewDidLoadIO = Signal<Void, NoError>.pipe()
    func viewDidLoad() {
        viewDidLoadIO.input.send(value: ())
    }

    private let removeAllObjcsIO = Signal<Void, NoError>.pipe()
    func removeAllObjs() {
        removeAllObjcsIO.input.send(value: ())
    }

    private let printSimilarPhotoObjectsIO = Signal<Void, NoError>.pipe()
    func printSimilarPhotoObjects() {
        printSimilarPhotoObjectsIO.input.send(value: ())
    }

    // MARK: Outputs

    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfElements(_ section: Int) -> Int {
        return 100
    }
}
