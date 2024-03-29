//
//  ThumbnailPhotoCarouselView.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/13/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit

final class ThumbnailPhotoCarouselView: NibInstantiableView {

    var emitter = EventEmitter<BehaviorEvent>()
    private var dataSource = [MainViewDisplayModel.PhotoModel]()
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewLayout: UICollectionViewFlowLayout!

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        collectionView.registerClass(forCellType: ContainerCollectionViewCell<ThumbnailPhotoView>.self)
    }
    
    func updatePhoto(to photoIndex: Int) {
        collectionView.scrollToItem(at: IndexPath(item: photoIndex, section: 0), at: .centeredHorizontally, animated: true)
    }
    
}

extension ThumbnailPhotoCarouselView: InputAppliable {
    typealias Input = (dataSource: MainViewDisplayModel.SimilarPhotosDisplayModel, thumbnailPhotoSwipeHandler: ((Int) -> Void)?)

    func apply(input: Input) {
        self.dataSource = input.dataSource.photoModels
        self.collectionView.reloadData()
        self.collectionView.setContentOffset(.zero, animated: false)
    }
}

extension ThumbnailPhotoCarouselView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = dataSource[indexPath.row]
        return collectionView.dequeueReusableCell(withType: ContainerCollectionViewCell<ThumbnailPhotoView>.self, for: indexPath)
            .applied(input: data)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let indexOfMajorCell = self.indexOfMajorCell()
        let indexPath = IndexPath(item: indexOfMajorCell, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        emitter.emit(event: .thumbnailSwipe(index: indexOfMajorCell))
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let indexOfMajorCell = self.indexOfMajorCell()
        let indexPath = IndexPath(item: indexOfMajorCell, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        emitter.emit(event: .thumbnailSwipe(index: indexOfMajorCell))
    }
    
    private func indexOfMajorCell() -> Int {
        let itemWidth = collectionViewLayout.itemSize.width
        let proportionalOffset = collectionViewLayout.collectionView!.contentOffset.x / itemWidth
        let index = Int(round(proportionalOffset))
        let safeIndex = max(0, min(dataSource.count - 1, index))
        return safeIndex
    }
}

extension ThumbnailPhotoCarouselView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        let width = height
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let collectionViewWidth = collectionView.frame.width
        let totalCellWidth = collectionView.frame.height
        let totalSpacingWidth: CGFloat = 10
        let leftInset = (collectionViewWidth - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: leftInset)
    }
}

// MARK: Emittable

extension ThumbnailPhotoCarouselView: BehaviorEventEmittable {
    enum BehaviorEvent {
        case thumbnailSwipe(index: Int)
    }
}
