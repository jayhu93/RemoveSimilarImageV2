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
    private let displayModel: MutableProperty<MainViewDisplayModel>

    init(dependency: Dependency) {
        (similarImageService, photoLibraryService, localDatabase) = dependency

        displayModel = MutableProperty(MainViewDisplayModel())

        localDatabase.outputs.getSimilarSetObjectsSignal.observeValues { [displayModel] in
            displayModel.value = MainViewDisplayModel($0)
        }

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
        case removeSelected(indexPath: IndexPath, selectedIndices: [Int])
        case keepAll(indexPath: IndexPath)
        case markDelete(indexPath: IndexPath, photoIndex: Int, isOn: Bool)
        case swipePhoto(indexPath: IndexPath, photoIndex: Int)
        case viewDidAppear
    }

    private let viewDidLoadIO = Signal<Void, NoError>.pipe()
    private let removeAllObjcsIO = Signal<Void, NoError>.pipe()
    private let printSimilarPhotoObjects = Signal<Void, NoError>.pipe()
    private let refreshControlActionIO = Signal<Void, NoError>.pipe()
    private let reachedPaginationOffsetYIO = Signal<Void, NoError>.pipe()
    private let removeAllIO = Signal<IndexPath, NoError>.pipe()
    private let removeSelectedIO = Signal<(IndexPath, [Int]), NoError>.pipe()
    private let keepAllIO = Signal<IndexPath, NoError>.pipe()
    private let markDeleteIO = Signal<(IndexPath, Int, Bool), NoError>.pipe()
    private let swipePhotoIO = Signal<(IndexPath, Int), NoError>.pipe()
    private let viewDidAppearIO = Signal<Void, NoError>.pipe()

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
        case .removeSelected(let indexPath, let selectedIndices):
            removeSelectedIO.input.send(value: (indexPath, selectedIndices))
        case .keepAll(let indexPath):
            keepAllIO.input.send(value: indexPath)
        case .markDelete(let indexPath, let photoIndex, let isOn):
            markDeleteIO.input.send(value: (indexPath, photoIndex, isOn))
        case .swipePhoto(let indexPath, let photoIndex):
            swipePhotoIO.input.send(value: (indexPath, photoIndex))
        case .viewDidAppear:
            viewDidAppearIO.input.send(value: ())
        }
    }

    // MARK: Outputs

    enum Output: Equatable {
        case reloadData
        case isRefreshing(isRefreshing: Bool)
    }

    private let outputIO = Signal<Output, NoError>.pipe()
    private(set) lazy var outputSignal = outputIO.output

    func numberOfSections() -> Int {
        return displayModel.value.numberOfSections()
    }

    func numberOfElements(inSection section: Int) -> Int {
        return displayModel.value.numberOfElements(inSection: section)
    }

    func element(at indexPath: IndexPath) -> MainViewDisplayModel.Element {
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

        similarImageService.outputs.isRefreshing.map {
            Output.isRefreshing(isRefreshing: $0)
        }.observeValues(outputIO.input.send)

        // MARK: Paginate here, load 50 images at a time

        Signal.merge(
            reachedPaginationOffsetYIO.output
            ).observeValues { [photoLibraryService, localDatabase] in
                // Fetch 50 photos and send them to similar photos service
                // if similar photo still process preview batch, then cancel the request
                let currentCount = localDatabase.outputs.numberOfPhotoObjects()
                guard currentCount > 0 else { return }
                photoLibraryService.inputs.fetchImage(currentCount)
        }

        Signal.merge(
            viewDidAppearIO.output,
            refreshControlActionIO.output
            ).observeValues { [photoLibraryService, localDatabase, displayModel] in
                localDatabase.inputs.deleteAllObjects()
                displayModel.value.removeAll()
                let currentCount = localDatabase.outputs.numberOfPhotoObjects()
//                photoLibraryService.inputs.fetchImage(currentCount)
                photoLibraryService.inputs.freshFetch(currentCount)
        }

        removeAllObjcsIO.output.observeValues { [weak self] in
            self?.localDatabase.inputs.deleteAllObjects()
        }

        keepAllIO.output.observeValues { [weak self] indexPath in
            guard let strongSelf = self else { return }
            switch strongSelf.displayModel.value.element(at: indexPath) {
            case .similarSet(let model):
                strongSelf.localDatabase.inputs.markKeepAll(model.setID)
            default: break
            }
        }

        removeAllIO.output.observeValues { [weak self] indexPath in
            guard let strongSelf = self else { return }
            switch strongSelf.displayModel.value.element(at: indexPath) {
            case .similarSet(let model):
                strongSelf.localDatabase.inputs.removeAll(model.setID)
            default: break
            }
        }

        removeSelectedIO.output.observeValues { [weak self] indexPath, selectedIndices in
            guard let strongSelf = self else { return }
            switch strongSelf.displayModel.value.element(at: indexPath) {
            case .similarSet(let model):
                strongSelf.localDatabase.inputs.removeSelected(model.setID, selectedIndices: selectedIndices)
            default: break
            }
        }
    }
}
