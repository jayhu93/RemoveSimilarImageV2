//
//  ThumbnailPhotoCarouselView.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/13/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit

final class ThumbnailPhotoCarouselView: NibInstantiableView {
    
    private var input: Input?
    
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

}

extension ThumbnailPhotoCarouselView: InputAppliable {
    typealias Input = [PhotoObject]

    func apply(input: Input) {
        self.input = input
        self.collectionView.reloadData()
    }
}

extension ThumbnailPhotoCarouselView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let input = input else { return 0 }
        return input.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let input = input else { return UICollectionViewCell() }
        return collectionView.dequeueReusableCell(withType: ContainerCollectionViewCell<ThumbnailPhotoView>.self, for: indexPath)
            .applied(input: input[indexPath.row])
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
        return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    }
}
