//
//  ThumbnailPhotoCarouselView.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/13/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit

final class ThumbnailPhotoCarouselView: NibInstantiableView {
    
    var thumbnailPhotoSwipeHandler: ((Int) -> Void)?
    
    private var dataSource = [PhotoObject]()
    
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
        collectionView.registerClass(forCellType: ContainerCollectionViewCell<ThumbnailPhotoView>.self)
    }
    
    func updatePhoto(to photoIndex: Int) {
        collectionView.scrollToItem(at: IndexPath(item: photoIndex, section: 0), at: .centeredHorizontally, animated: true)
    }
    
}

extension ThumbnailPhotoCarouselView: InputAppliable {
    typealias Input = (dataSource: [PhotoObject], thumbnailPhotoSwipeHandler: ((Int) -> Void)?)

    func apply(input: Input) {
        self.dataSource = input.dataSource
        self.thumbnailPhotoSwipeHandler = input.thumbnailPhotoSwipeHandler
        self.collectionView.reloadData()
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
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        thumbnailPhotoSwipeHandler?(index)
        print("thumbnail photo carousel view scroll view did end decelerating")
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
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 5)
    }
}
