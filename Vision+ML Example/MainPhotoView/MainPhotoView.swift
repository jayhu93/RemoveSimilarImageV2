//
//  MainViewCollectionCell.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/11/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import Swinject

final class MainPhotoView: NibInstantiableView, InputAppliable {

    @IBOutlet private weak var previewPhotoCarouselView: PreviewPhotoCarouselView!
    @IBOutlet private weak var thumbnailPhotoCarouselView: ThumbnailPhotoCarouselView!

    typealias Input = [PhotoObject]
    
    func apply(input: [PhotoObject]) {
        previewPhotoCarouselView.apply(input: input)
        thumbnailPhotoCarouselView.apply(input: input)
    }
}
