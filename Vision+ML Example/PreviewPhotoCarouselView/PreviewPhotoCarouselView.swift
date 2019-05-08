//
//  PreviewPhotoCarouselView.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/12/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit

final class PreviewPhotoCarouselView: NibInstantiableView {

    private var input: Input?
    
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
    typealias Input = [PhotoObjectData]

    func apply(input: Input) {
        self.input = input
        self.collectionView.reloadData()
    }
}

// MARK: UICollectionViewDataSource

extension PreviewPhotoCarouselView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let input = input else { return UICollectionViewCell() }
        let data = input[indexPath.row]
        return collectionView.dequeueReusableCell(withType: ContainerCollectionViewCell<PreviewPhotoView>.self, for: indexPath).applied(input: data)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let input = input else { return 0 }
        return input.count
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
