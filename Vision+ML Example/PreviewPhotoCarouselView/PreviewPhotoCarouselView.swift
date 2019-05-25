//
//  PreviewPhotoCarouselView.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/12/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit

final class PreviewPhotoCarouselView: NibInstantiableView {

    var emitter = EventEmitter<BehaviorEvent>()
    var dataSource = [PhotoObject]()
    
    @IBOutlet private weak var collectionView: UICollectionView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        collectionView.registerClass(forCellType: ContainerCollectionViewCell<PreviewPhotoView>.self)
    }
    
    func updatePhoto(to photoIndex: Int) {
        collectionView.scrollToItem(at: IndexPath(item: photoIndex, section: 0), at: .centeredHorizontally, animated: true)
    }

}

// MARK: Input Appliable

extension PreviewPhotoCarouselView: InputAppliable {
    typealias Input = (dataSource: MainViewDisplayModel.SimilarPhotosDisplayModel, previewPhotoSwipeHandler: ((Int) -> Void)?)

    func apply(input: Input) {
        self.dataSource = input.dataSource.photos
        self.collectionView.reloadData()
        self.collectionView.setContentOffset(.zero, animated: false)
    }
}

// MARK: UICollectionViewDataSource

extension PreviewPhotoCarouselView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = dataSource[indexPath.row]
        return collectionView.dequeueReusableCell(withType: ContainerCollectionViewCell<PreviewPhotoView>.self, for: indexPath).applied(input: data)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        emitter.emit(event: .photoSwipe(index: index))
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension PreviewPhotoCarouselView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width,
                      height: collectionView.frame.size.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

// MARK: Emittable

extension PreviewPhotoCarouselView: BehaviorEventEmittable {
    enum BehaviorEvent {
        case photoSwipe(index: Int)
    }
}
