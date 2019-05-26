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
        self.collectionView.reloadData()
        self.collectionView.setContentOffset(.zero, animated: false)
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
            case .markDelete(let isOn ,let index):
                strongSelf.emitter.emit(event: .markDelete(isOn: isOn, index: index))
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
        case markDelete(isOn: Bool, index: Int)
    }
}
