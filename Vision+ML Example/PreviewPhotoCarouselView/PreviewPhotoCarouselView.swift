//
//  PreviewPhotoCarouselView.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/12/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit

final class PreviewPhotoCarouselView: NibInstantiableView {

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
        collectionView.registerClass(forCellType: ContainerCollectionViewCell<PreviewPhotoView>.self)
    }

}

// MARK: Input Appliable

extension PreviewPhotoCarouselView: InputAppliable {
    typealias Input = String

    func apply(input: String) {
        print("x")
    }
}

// MARK: UICollectionViewDataSource

extension PreviewPhotoCarouselView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withType: ContainerCollectionViewCell<PreviewPhotoView>.self, for: indexPath)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension PreviewPhotoCarouselView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 10,
                      height: collectionView.frame.size.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    }
}
