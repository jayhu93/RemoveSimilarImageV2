//
//  PreviewPhotoView.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/12/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import Photos

final class PreviewPhotoView: NibInstantiableView {
    let imageManager = PHImageManager()

    @IBOutlet private weak var imageView: UIImageView!
    
}

extension PreviewPhotoView: InputAppliable {
    typealias Input = PhotoObject

    func apply(input: Input) {
        let id = input.id
        
        // TODO: Will most likely move this block our of this view
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: .none).firstObject!
        
        let thumbnailSize = CGSize(width: 300, height: 300)
        
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFit, options: .none) { (image, info) in
            self.imageView.image = image
        }
    }
}
