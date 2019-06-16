//
//  PreviewPhotoCollectionCell.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/12/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import Photos

final class PreviewPhotoCollectionCell: UICollectionViewCell {
    let imageManager = PHImageManager()
    var photoIndex: Int?
    let emitter = EventEmitter<BehaviorEvent>()

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var deleteSwitch: UISwitch!

    @IBAction func markDelete(_ sender: UISwitch) {
        guard let photoIndex = photoIndex else { return }
        emitter.emit(event: .markDelete(index: photoIndex, isOn: sender.isOn))
    }
}

extension PreviewPhotoCollectionCell: InputAppliable {
    typealias Input = (photoObject: MainViewDisplayModel.PhotoModel, photoIndex: Int, isOn: Bool)

    func apply(input: Input) {
        let id = input.photoObject.photoObject.id
        photoIndex = input.photoIndex
        deleteSwitch.setOn(input.isOn, animated: false)

        // TODO: Will most likely move this block our of this view
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: .none).firstObject!
        
        let thumbnailSize = CGSize(width: 1080, height: 1080)

        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFit, options: .none) { (image, info) in
            self.imageView.image = image
        }
    }
}

// MARK: Emittable

extension PreviewPhotoCollectionCell: BehaviorEventEmittable {
    enum BehaviorEvent {
        case markDelete(index: Int, isOn: Bool)
    }
}
