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

    var emitter = EventEmitter<BehaviorEvent>()
    private var indexPath: IndexPath?

    @IBOutlet private weak var myContentView: UIView!
    @IBOutlet private weak var cardContainerView: DropShadowView!
    @IBOutlet private weak var previewPhotoCarouselView: PreviewPhotoCarouselView! {
        didSet {
            previewPhotoCarouselView.observe { [weak self] in
                guard let strongSelf = self else { return }
                switch $0 {
                case .photoSwipe(let index):
                    strongSelf.thumbnailPhotoCarouselView.updatePhoto(to: index)
                case .markDelete(let index, let isOn):
                    guard let indexPath = strongSelf.indexPath else { return }
                    strongSelf.emitter.emit(event: .markDelete(indexPath: indexPath, photoIndex: index, isOn: isOn))
                }
            }
        }
    }
    @IBOutlet private weak var thumbnailPhotoCarouselView: ThumbnailPhotoCarouselView! {
        didSet {
            thumbnailPhotoCarouselView.observe { [weak self] in
                guard let strongSelf = self else { return }
                switch $0 {
                case .thumbnailSwipe(let index):
                    strongSelf.previewPhotoCarouselView.updatePhoto(to: index)
                }
            }
        }
    }
    @IBOutlet private weak var actionView: SimilarSetActionView! {
        didSet {
            actionView.observe { [weak self] in
                guard let strongSelf = self, let indexPath = strongSelf.indexPath else { return }
                switch $0 {
                case .removeAll: strongSelf.emitter.emit(event: .removeAll(indexPath: indexPath))
                case .removeSelected: strongSelf.emitter.emit(event: .removeSelected(indexPath: indexPath))
                case .keepAll: strongSelf.emitter.emit(event: .keepAll(indexPath: indexPath))
                }
            }
        }
    }

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
    
    typealias Input = (displayModel: MainViewDisplayModel.SimilarPhotosDisplayModel, indexPath: IndexPath)
    
    func apply(input: Input) {

        self.indexPath = input.indexPath

        let previewPhotoSwipeHandler: ((Int) -> Void)? = { [weak self] photoIndex  in
            self?.thumbnailPhotoCarouselView.updatePhoto(to: photoIndex)
        }
        
        let thumbnailPhotoSwipeHandler: ((Int) -> Void)? = { [weak self] photoIndex in
            self?.previewPhotoCarouselView.updatePhoto(to: photoIndex)
        }
        
        previewPhotoCarouselView.apply(input: (input.displayModel, previewPhotoSwipeHandler))
        thumbnailPhotoCarouselView.apply(input: (input.displayModel, thumbnailPhotoSwipeHandler))
    }
}

extension MainPhotoView: BehaviorEventEmittable {
    enum BehaviorEvent {
        case removeAll(indexPath: IndexPath)
        case removeSelected(indexPath: IndexPath)
        case keepAll(indexPath: IndexPath)
        case markDelete(indexPath: IndexPath, photoIndex: Int, isOn: Bool)
    }
}
