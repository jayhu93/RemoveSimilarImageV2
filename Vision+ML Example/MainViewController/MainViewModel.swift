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
    func element(at indexPath: IndexPath) -> [PhotoObjectData]
    var reloadSignal: Signal<Void, NoError> { get }
}

protocol MainViewModelType {
    var inputs: MainViewModelInputs { get }
    var outputs: MainViewModelOutpus { get }
}

struct PhotoObjectData {
    var photoObject: PhotoObject
    var image: UIImage?
}

final class MainViewModel: MainViewModelType, MainViewModelInputs, MainViewModelOutpus {
    
    typealias Dependency = (
        SimilarImageServiceType,
        PhotoLibraryServiceType,
        LocalDatabaseType
    )
    
    var displayModel: Property<[[PhotoObjectData]]>
    
    init(dependency: Dependency) {
        let (similarImageService, photoLibraryService, localDatabase) = dependency
        print("got similar image service: \(similarImageService)")

        
        displayModel = Property(initial: [[PhotoObjectData]](),
                                then: localDatabase.outputs.similarPhotoGroupsSignal)
        
        reloadSignal = displayModel.signal.map { _ in }
        
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

        printSimilarPhotoObjectsIO.output.observeValues { _ in
            localDatabase.inputs.getSimilarObjectGroups()
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
        return displayModel.value.count
    }
    
    func element(at indexPath: IndexPath) -> [PhotoObjectData] {
        return displayModel.value[indexPath.row]
    }

    
    let reloadSignal: Signal<Void, NoError>
}
