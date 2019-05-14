//
//  MainViewCollectionCell.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/11/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import Swinject

final class MainPhotoView: UICollectionViewCell, InputAppliable {

    @IBOutlet private weak var myContentView: UIView!
    @IBOutlet private weak var cardContainerView: DropShadowView!
    @IBOutlet private weak var previewPhotoCarouselView: PreviewPhotoCarouselView!
    @IBOutlet private weak var thumbnailPhotoCarouselView: ThumbnailPhotoCarouselView!

    let cornerRadius : CGFloat = 25.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        cardContainerView.layer.cornerRadius = cornerRadius
        cardContainerView.layer.shadowColor = UIColor.gray.cgColor
        cardContainerView.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
        cardContainerView.layer.shadowRadius = 15.0
        cardContainerView.layer.shadowOpacity = 0.9
        
        // setting shadow path in awakeFromNib doesn't work as the bounds / frames of the views haven't got initialized yet
        // at this point the cell layout position isn't known yet
        
        myContentView.layer.cornerRadius = cornerRadius
        myContentView.clipsToBounds = true
    }
    
    typealias Input = MainViewDisplayModel.SimilarPhotosDisplayModel
    
    func apply(input: Input) {
        
        let previewPhotoSwipeHandler: ((Int) -> Void)? = { [weak self] photoIndex  in
            self?.thumbnailPhotoCarouselView.updatePhoto(to: photoIndex)
        }
        
        let thumbnailPhotoSwipeHandler: ((Int) -> Void)? = { [weak self] photoIndex in
            self?.previewPhotoCarouselView.updatePhoto(to: photoIndex)
        }
        
        previewPhotoCarouselView.apply(input: (input, previewPhotoSwipeHandler))
        thumbnailPhotoCarouselView.apply(input: (input, thumbnailPhotoSwipeHandler))
    }
}


class DropShadowView: UIView {
    var presetCornerRadius : CGFloat = 25.0
    
    /*
     once the bounds of the drop shadow view (container view) is initialized,
     the bounds variable value will be set/updated and the
     setupShadow method will run
     */
    override var bounds: CGRect {
        didSet {
            setupShadowPath()
        }
    }
    
    private func setupShadowPath() {
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: presetCornerRadius).cgPath
        
        // further optimization by rasterizing the container view and its shadow into bitmap instead of dynamically rendering it every time
        // take note that the rasterized bitmap will be saved into memory and it might take quite some memory if you have many cells
        
        // self.layer.shouldRasterize = true
        // self.layer.rasterizationScale = UIScreen.main.scale
    }
    
}
