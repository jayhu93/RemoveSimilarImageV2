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

protocol ServiceType {
    func response<R: RequestType>(from request: R) -> SignalProducer<R.Response, Error>
}

struct RawPhoto {
    var id: String
    var image: UIImage
}

enum PhotoServiceAlbumAvailability {
    case available
    case denied
    case notDetermined
}

// MARK: PhotoLibraryServiceInputs

protocol PhotoLibraryServiceInputs {
    func fetchImage()
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

final class PhotoLibraryService: NSObject, PHPhotoLibraryChangeObserver, PhotoLibraryServiceType, PhotoLibraryServiceInputs, PhotoLibraryServiceOutputs, ServiceType {

    typealias Dependency = SchedulerProviderType

    private let isRunningProperty = MutableProperty(false)

    private let fetchResultProperty = MutableProperty<PHFetchResult<PHAsset>?>(nil)
    private let photoObserver: Signal<RawPhoto, NoError>.Observer
    private let assetCollectionProperty = MutableProperty<PHAssetCollection?>(nil)
    fileprivate let imageManager = PHCachingImageManager()
    let thumbnailSize = CGSize.init(width: 30, height: 30)

    // Init

    init(dependency: Dependency) {
        let schedulerProvider = dependency
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

        fetchImagesIO.output.observeValues { [weak self] in
                guard let strongSelf = self else { return }
                let allPhotoOptions = PHFetchOptions()
                allPhotoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                let fetch = PHAsset.fetchAssets(with: allPhotoOptions)
                strongSelf.fetchResultProperty.value = fetch
        }

        fetchResultProperty.signal.observeValues { [weak self] assets in
            let totalAssetCount = assets?.count ?? 0
            let indexSet = IndexSet(0..<totalAssetCount)
            guard let assets = assets?.objects(at: indexSet) else { return }
            guard let strongSelf = self else { return }
            var counter = 0
            for asset in assets {
                counter += 1
                print("counter: \(counter)")
                strongSelf.imageManager.requestImage(for: asset, targetSize: strongSelf.thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
                    // UIKit may have recycled this cell by the handler's activation time.
                    // Set the cell's thumbnail image only if it's still showing the same asset.
                    guard let img = image else { return }
                    let id = asset.localIdentifier
                    let rawPhoto = RawPhoto(id: id, image: img)
                    photoObserver.send(value: rawPhoto)
                })
            }
        }
    }

    // MARK: PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: fetchResultProperty.value ?? PHFetchResult<PHAsset>())
            else { return }
        DispatchQueue.main.sync {
            fetchResultProperty.value = changes.fetchResultAfterChanges
        }
    }

    // MARK: ServiceType
    public func response<R: RequestType>(from request: R) -> SignalProducer<R.Response, Error> {
        return SignalProducer(value: request)
            .withLatest(from: apiConfigurationProvider.outputs.configuration)
            .flatMap(.merge) { [apiClient] request, configuration -> SignalProducer<R.Response, Error> in
                self.token(with: configuration).flatMap(.merge) {
                    apiClient.response(from: request, configuration: configuration, accessToken: $0.token.accessToken)
                }
            }
            .on(failed: self.hook(error:))
    }

    // MARK: PhotoLibraryServiceType

    var inputs: PhotoLibraryServiceInputs { return self }
    var outputs: PhotoLibraryServiceOutputs { return self }

    // MARK: PhotoLibraryServiceInputs

    private let fetchImagesIO = Signal<Void, NoError>.pipe()
    func fetchImage() {
        fetchImagesIO.input.send(value: ())
    }

    // MARK: PhotoLibraryServiceOutputs
    let deviceAvailabilityProperty: Property<PhotoServiceAlbumAvailability>
    let photoSignal: Signal<RawPhoto, NoError>

}

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
