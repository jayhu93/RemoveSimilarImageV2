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

    @IBOutlet weak var imageView: UIImageView!

    let switch1 = UISwitch()

    @IBAction func markDelete(_ sender: UISwitch) {
        guard let photoIndex = photoIndex else { return }
        CATransaction.setCompletionBlock { [weak self] in
            self?.emitter.emit(event: .markDelete(isOn: sender.isOn, index: photoIndex))
        }
    }
}

extension PreviewPhotoCollectionCell: InputAppliable {
    typealias Input = (photoObject: PhotoObject, photoIndex: Int)

    func apply(input: Input) {
        let id = input.photoObject.id
        photoIndex = input.photoIndex
        
        // TODO: Will most likely move this block our of this view
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: .none).firstObject!
        
        let thumbnailSize = CGSize(width: 300, height: 300)

        self.imageView.image = UIImage(named: "image.jpg")
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFit, options: .none) { (image, info) in
            self.imageView.image = image
        }
    }
}

// MARK: Emittable

extension PreviewPhotoCollectionCell: BehaviorEventEmittable {
    enum BehaviorEvent {
        case markDelete(isOn: Bool, index: Int)
    }
}
