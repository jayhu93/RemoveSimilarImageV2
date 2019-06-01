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

final class MainViewModel: SectionedDataSource {
    
    typealias Dependency = (
        SimilarImageServiceType,
        PhotoLibraryServiceType,
        LocalDatabaseType
    )

    private let similarImageService: SimilarImageServiceType
    private let photoLibraryService: PhotoLibraryServiceType
    private let localDatabase: LocalDatabaseType
    private let displayModel: Property<MainViewDisplayModel>

    init(dependency: Dependency) {
        (similarImageService, photoLibraryService, localDatabase) = dependency

        displayModel = Property(
            initial: MainViewDisplayModel(),
            then: localDatabase.outputs.getSimilarSetObjectsSignal
                .map { MainViewDisplayModel($0) }
        )

        bind()
    }

    // MARK: Inputs
    
    enum Input: Equatable {
        case viewDidLoad
        case removeAllObjs
        case printSimilarPhotoObjects
        case refreshControlAction
        case reachedPaginationOffsetY
        case removeAll(indexPath: IndexPath)
        case removeSelected(indexPath: IndexPath)
        case keepAll(indexPath: IndexPath)
        case markDelete(indexPath: IndexPath, photoIndex: Int, isOn: Bool)
        case swipePhoto(indexPath: IndexPath, photoIndex: Int)
    }

    private let viewDidLoadIO = Signal<Void, NoError>.pipe()
    private let removeAllObjcsIO = Signal<Void, NoError>.pipe()
    private let printSimilarPhotoObjects = Signal<Void, NoError>.pipe()
    private let refreshControlActionIO = Signal<Void, NoError>.pipe()
    private let reachedPaginationOffsetYIO = Signal<Void, NoError>.pipe()
    private let removeAllIO = Signal<IndexPath, NoError>.pipe()
    private let removeSelectedIO = Signal<IndexPath, NoError>.pipe()
    private let keepAllIO = Signal<IndexPath, NoError>.pipe()
    private let markDeleteIO = Signal<(IndexPath, Int, Bool), NoError>.pipe()
    private let swipePhotoIO = Signal<(IndexPath, Int), NoError>.pipe()

    func apply(input: Input) {
        switch input {
        case .viewDidLoad:
            viewDidLoadIO.input.send(value: ())
        case .removeAllObjs:
            removeAllObjcsIO.input.send(value: ())
        case .printSimilarPhotoObjects:
            printSimilarPhotoObjects.input.send(value: ())
        case .refreshControlAction:
            refreshControlActionIO.input.send(value: ())
        case .reachedPaginationOffsetY:
            reachedPaginationOffsetYIO.input.send(value: ())
        case .removeAll(let indexPath):
            removeAllIO.input.send(value: indexPath)
        case .removeSelected(let indexPath):
            removeSelectedIO.input.send(value: indexPath)
        case .keepAll(let indexPath):
            keepAllIO.input.send(value: indexPath)
        case .markDelete(let indexPath, let photoIndex, let isOn):
            markDeleteIO.input.send(value: (indexPath, photoIndex, isOn))
        case .swipePhoto(let indexPath, let photoIndex):
            swipePhotoIO.input.send(value: (indexPath, photoIndex))
        }
    }

    // MARK: Outputs

    enum Output: Equatable {
        case reloadData
    }

    private let outputIO = Signal<Output, NoError>.pipe()
    private(set) lazy var outputSignal = outputIO.output

    func numberOfSections() -> Int {
        return displayModel.value.numberOfSections()
    }

    func numberOfElements(inSection section: Int) -> Int {
        return displayModel.value.numberOfElements(inSection: section)
    }

    func element(at indexPath: IndexPath) -> MainViewDisplayModel.SimilarPhotosDisplayModel {
        return displayModel.value.element(at: indexPath)
    }

    // MARK: Bind
    private func bind() {
        bindIO()
    }

    private func bindIO() {

        // MARK: Reload

        displayModel.signal
            .map { _ in
            Output.reloadData
        }.observeValues(outputIO.input.send)

        // MARK: Paginate here, load 50 images at a time

        Signal.merge(
            viewDidLoadIO.output,
            reachedPaginationOffsetYIO.output
            ).observeValues { [photoLibraryService] in
                // Fetch 50 photos and send them to similar photos service
                // if similar photo still process preview batch, then cancel the request
                photoLibraryService.inputs.fetchImage()
        }

//        similarImageService.outputs.similarSetObjects.observeValues { similarSetObjects in
            // update display model
            // MainViewModel only needs to work with one service
            // Do i even need realm database
//            displayModel.value.updateSimilarSetObjects(similarSetObjects)
//        }

//        similarImageService.outputs.similarImageResultSignal.observeValues { [weak self] photoResult in
//            let photoObject = PhotoObject()
//            photoObject.id = photoResult.id
//            let similarArray = photoResult.results.map { $0.offset }
//            photoObject.similarArray.append(objectsIn: similarArray)
//            self?.localDatabase.inputs.addPhotoObject(photoObject)
//        }
//
//        photoLibraryService.outputs.photoSignal.observeValues { [weak self] rawPhoto in
//            self?.similarImageService.inputs.analyze(rawPhoto: rawPhoto)
//        }
//
//        viewDidLoadIO.output.observeValues { [weak self] in
//            self?.photoLibraryService.inputs.fetchImage()
//        }
//
//        localDatabase.outputs.getSimilarSetObjectsSignal.observeValues { [weak self] similarSetObjects in
//            self?.displayModel.value.updateSimilarSetObjects(similarSetObjects)
//        }
//
//        displayModel.signal.observeValues { [weak self] _ in
//            self?.outputIO.input.send(value: .reloadData)
//        }
//
//        markDeleteIO.output.observeValues { values in
//            let (indexPath, photoIndex, isOn) = values
//            self.displayModel.value.markDelete(indexPath, photoIndex, isOn)
//        }
//
//        swipePhotoIO.output.observeValues { indexPath, photoIndex in
//            self.displayModel.value.swipePhoto(indexPath, photoIndex)
//        }
//
//        // Database action
//
//        removeAllIO.output.observeValues { [weak self] indexPath in
//            guard let element = self?.displayModel.value.element(at: indexPath) else { return }
//            let ids = element.photoModels.map { $0.photoObject.id }
//            self?.localDatabase.inputs.deletePhotoObject(withIds: ids)
//        }
//
//        // DEBUG
//
        removeAllObjcsIO.output.observeValues { [weak self] in
            self?.localDatabase.inputs.deleteAllObjects()
        }
//
//        printSimilarPhotoObjects.output.observeValues { [weak self] _ in
//            self?.localDatabase.inputs.getSimilarObjectGroups()
////            self?.localDatabase.inputs.getSimilarSetsObject()
//        }

    }
}
