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
    var dataSource = [MainViewDisplayModel.PhotoModel]()
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        collectionView.registerNib(forCellType: PreviewPhotoCollectionCell.self)
    }
    
    func updatePhoto(to photoIndex: Int) {
        collectionView.scrollToItem(at: IndexPath(item: photoIndex, section: 0), at: .centeredHorizontally, animated: true)
    }

}

// MARK: Input Appliable

extension PreviewPhotoCarouselView: InputAppliable {
    typealias Input = (dataSource: MainViewDisplayModel.SimilarPhotosDisplayModel, previewPhotoSwipeHandler: ((Int) -> Void)?)

    func apply(input: Input) {
        self.dataSource = input.dataSource.photoModels
        self.pageControl.numberOfPages = input.dataSource.photoModels.count
        self.pageControl.currentPage = 0
        self.collectionView.reloadData()
        let indexPath = IndexPath(item: input.dataSource.currentIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
}

// MARK: UICollectionViewDataSource

extension PreviewPhotoCarouselView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = dataSource[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withType: PreviewPhotoCollectionCell.self, for: indexPath).applied(input: (data, indexPath.row))
        cell.observe { [weak self] in
            guard let strongSelf = self else { return }
            switch $0 {
            case .markDelete(let index ,let isOn):
                strongSelf.emitter.emit(event: .markDelete(index: index, isOn: isOn))
            }
        }
        return cell
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
        pageControl.currentPage = index
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
}

// MARK: Emittable

extension PreviewPhotoCarouselView: BehaviorEventEmittable {
    enum BehaviorEvent {
        case photoSwipe(index: Int)
        case markDelete(index: Int, isOn: Bool)
    }
}
