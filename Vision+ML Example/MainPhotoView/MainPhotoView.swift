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

    typealias Input = [PhotoObjectData]
    @IBOutlet weak var previewPhotoCarouselView: PreviewPhotoCarouselView!
    
    func apply(input: [PhotoObjectData]) {
        previewPhotoCarouselView.apply(input: input)
    }
}
