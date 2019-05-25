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
    private lazy var displayModel: MutableProperty<MainViewDisplayModel> = {
        return MutableProperty.init(MainViewDisplayModel())
    }()

    init(dependency: Dependency) {
        (similarImageService, photoLibraryService, localDatabase) = dependency
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
        case markForDelete(indexPath: IndexPath, photoIndex: Int)
    }

    private let viewDidLoadIO = Signal<Void, NoError>.pipe()
    private let removeAllObjcsIO = Signal<Void, NoError>.pipe()
    private let printSimilarPhotoObjects = Signal<Void, NoError>.pipe()
    private let refreshControlActionIO = Signal<Void, NoError>.pipe()
    private let reachedPaginationOffsetY = Signal<Void, NoError>.pipe()
    private let removeAllIO = Signal<IndexPath, NoError>.pipe()
    private let removeSelectedIO = Signal<IndexPath, NoError>.pipe()
    private let keepAllIO = Signal<IndexPath, NoError>.pipe()
    private let markForDeleteIO = Signal<(IndexPath, Int), NoError>.pipe()

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
            reachedPaginationOffsetY.input.send(value: ())
        case .removeAll(let indexPath):
            removeAllIO.input.send(value: indexPath)
        case .removeSelected(let indexPath):
            removeSelectedIO.input.send(value: indexPath)
        case .keepAll(let indexPath):
            keepAllIO.input.send(value: indexPath)
        case .markForDelete(let indexPath, let photoIndex):
            markForDeleteIO.input.send(value: (indexPath, photoIndex))
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

    func element(at indexPath: IndexPath) -> MainViewDisplayModel.ItemType {
        return displayModel.value.element(at: indexPath)
    }

    // MARK: Bind
    private func bind() {
        bindIO()
    }

    private func bindIO() {
        similarImageService.outputs.similarImageResultSignal.observeValues { [weak self] photoResult in
            let photoObject = PhotoObject()
            photoObject.id = photoResult.id
            let similarArray = photoResult.results.map { $0.offset }
            photoObject.similarArray.append(objectsIn: similarArray)
            self?.localDatabase.inputs.addPhotoObject(photoObject)
        }

        photoLibraryService.outputs.photoSignal.observeValues { [weak self] rawPhoto in
            self?.similarImageService.inputs.analyze(rawPhoto: rawPhoto)
        }

        viewDidLoadIO.output.observeValues { [weak self] in
            self?.photoLibraryService.inputs.fetchImage()
        }

        removeAllObjcsIO.output.observeValues { [weak self] in
            self?.localDatabase.inputs.deleteAllObjects()
        }

        printSimilarPhotoObjects.output.observeValues { [weak self] _ in
            self?.localDatabase.inputs.getSimilarObjectGroups()
        }

        localDatabase.outputs.similarPhotoGroupsSignal.observeValues { [weak self] in
            self?.displayModel.value.appendNewSimilarGroup($0)
        }

        displayModel.signal.observeValues { [weak self] _ in
            self?.outputIO.input.send(value: .reloadData)
        }
    }
}
