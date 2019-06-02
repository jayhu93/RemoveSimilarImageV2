//
//  PhotoLibraryService.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 3/8/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import Photos
import ReactiveSwift
import Result
import ImageIO
import ReactiveCocoa

struct RawPhoto {
    var id: String
    var image: UIImage
    var timestamp: Date
}

enum PhotoServiceAlbumAvailability {
    case available
    case denied
    case notDetermined
}

// MARK: PhotoLibraryServiceInputs

protocol PhotoLibraryServiceInputs {
    func fetchImage(_ currentCount: Int)
}

// MARK: PhotoLibraryServiceOutputs

protocol PhotoLibraryServiceOutputs {
    var photoSignal: Signal<RawPhoto, NoError> { get }
    var deviceAvailabilityProperty: Property<PhotoServiceAlbumAvailability> { get }
}

// MARK: PhotoLibraryServiceType

protocol PhotoLibraryServiceType {
    var inputs: PhotoLibraryServiceInputs { get }
    var outputs: PhotoLibraryServiceOutputs { get }
}

final class PhotoLibraryService: NSObject, PHPhotoLibraryChangeObserver, PhotoLibraryServiceType, PhotoLibraryServiceInputs, PhotoLibraryServiceOutputs {

    typealias Dependency = (SchedulerProviderType, SimilarImageServiceType, LocalDatabaseType)

    private let isRunningProperty = MutableProperty(false)

    private let fetchResultProperty = MutableProperty<[PHAsset]>([])
    private let photoObserver: Signal<RawPhoto, NoError>.Observer
    private let assetCollectionProperty = MutableProperty<PHAssetCollection?>(nil)
    fileprivate let imageManager = PHCachingImageManager()
    let thumbnailSize = CGSize.init(width: 30, height: 30)
    private let similarImageService: SimilarImageServiceType

    let dispatchGroup = DispatchGroup()
    // Init

    init(dependency: Dependency) {
        let (schedulerProvider, similarImageService, localDatabase) = dependency
        self.similarImageService = similarImageService
        let (photoSignal, photoObserver) = Signal<RawPhoto, NoError>.pipe()
        self.photoSignal = photoSignal.observe(on: schedulerProvider.scheduler(with: .ui))
        self.photoObserver = photoObserver

        let deviceAvailabilityProperty: Property<PhotoServiceAlbumAvailability>
        // check authorizationStatus for photo albulms
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            let signal = isRunningProperty.signal
                .filter { $0 }
                .take(first: 1).flatMap(.merge) { _ -> SignalProducer<PhotoServiceAlbumAvailability, NoError> in
                    PHPhotoLibrary.reactive.requestAccess()
                        .map { granted -> PhotoServiceAlbumAvailability in
                            if granted {
                                return .available
                            } else {
                                return .denied
                            }
                    }
                }
                .observe(on: schedulerProvider.scheduler(with: .ui))
            deviceAvailabilityProperty = Property(initial: .notDetermined, then: signal)
        case .authorized:
            deviceAvailabilityProperty = Property(value: .available)
        case .denied, .restricted:
            deviceAvailabilityProperty = Property(value: .denied)
        }

        self.deviceAvailabilityProperty = deviceAvailabilityProperty

        super.init()
        PHPhotoLibrary.shared().register(self)

//        let scheduler = schedulerProvider.scheduler(with: .queue(.init(name: "com.poeticsyntax.Photo")))

        fetchImagesIO.output.skipRepeats()
            .observeValues { [weak self] currentCount in
            // Fetch 50 photos and send them to similar photos service
            // if similar photo still process preview batch, then cancel the request
                guard let strongSelf = self else { return }
                let allPhotoOptions = PHFetchOptions()
                allPhotoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                let fetch = PHAsset.fetchAssets(with: allPhotoOptions)

                guard fetch.count > 0 else { return }

                let begin = currentCount - 1
                let possibleEnd = begin + 50
                let lastIndex = fetch.count - 1
                let end = lastIndex > possibleEnd ? possibleEnd : lastIndex
                let indexSet = IndexSet(currentCount...end)

                let assets = fetch.objects(at: indexSet)

                strongSelf.fetchResultProperty.value = assets
        }

        fetchResultProperty.signal.observeValues { [weak self] assets in
            var rawPhotos = [RawPhoto]()
            guard let strongSelf = self else { return }
            for asset in assets {
                // make sure the asset is not yet in the database
                guard !localDatabase.inputs.existInDatabase(asset.localIdentifier) else { break }
                strongSelf.dispatchGroup.enter()
                strongSelf.imageManager.requestImage(for: asset, targetSize: strongSelf.thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { [ weak self] image, info in
                    guard let isThumbnailInt = info?["PHImageResultIsDegradedKey"] as? Int else { return }
                    guard let isThunbmail = Bool(exactly: isThumbnailInt as NSNumber) else { return }
                    guard isThunbmail else { return }

                    guard let innerStrongSelf = self else { return }
                    guard let img = image else { return }
                    let id = asset.localIdentifier
                    let rawPhoto = RawPhoto(id: id, image: img, timestamp: asset.creationDate!)
                    rawPhotos.append(rawPhoto)
                    innerStrongSelf.dispatchGroup.leave()
                })
            }
            strongSelf.dispatchGroup.notify(queue: DispatchQueue.global(qos: .background)) {
                similarImageService.inputs.analyze(rawPhotos: rawPhotos)
            }
        }
    }

    // MARK: PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // TODO: Do something here
//        guard let changes = changeInstance.changeDetails(for: fetchResultProperty.value ?? PHFetchResult<PHAsset>())
//            else { return }
//        DispatchQueue.main.sync {
//            fetchResultProperty.value = changes.fetchResultAfterChanges
//        }
    }

    // MARK: PhotoLibraryServiceType

    var inputs: PhotoLibraryServiceInputs { return self }
    var outputs: PhotoLibraryServiceOutputs { return self }

    // MARK: PhotoLibraryServiceInputs

    private let fetchImagesIO = Signal<Int, NoError>.pipe()
    func fetchImage(_ currentCount: Int) {
        fetchImagesIO.input.send(value: currentCount)
    }

    // MARK: PhotoLibraryServiceOutputs
    let deviceAvailabilityProperty: Property<PhotoServiceAlbumAvailability>
    let photoSignal: Signal<RawPhoto, NoError>

}

// MARK: Request access extension

private extension Reactive where Base: PHPhotoLibrary {
    static func requestAccess() -> SignalProducer<Bool, NoError> {
        return .init { (observer, _) in
            Base.requestAuthorization {
                switch $0 {
                case .authorized:
                    observer.send(value: true)
                default:
                    observer.send(value: false)
                }
                observer.sendCompleted()
            }
        }
    }
}
