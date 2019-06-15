//
//  MainViewDisplayModel.swift
//  RemoveSimilarImages
//
//  Created by Yupin Hu on 5/12/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

struct MainViewDisplayModel {

    enum Element {
        case similarSet(SimilarPhotosDisplayModel)
        case ad
    }

    var elements = [Element]()


    init(similarSets: [SimilarPhotosDisplayModel] = []) {
        var elements = similarSets.map { Element.similarSet($0) }

        for (index, _) in elements.enumerated() {
            guard index != 0 else { continue }
            if index % 4 == 0 {
                elements.insert(Element.ad, at: index)
            }
        }

        self.elements = elements
    }

    init(_ simialrSetObjects: [SimilarSetObject]) {
        let newSimilarSets = simialrSetObjects.map {
            SimilarPhotosDisplayModel(
                photoModels: $0.photoObjects.map { PhotoModel(photoObject: $0) }
            )
        }
        var elements = newSimilarSets.map { Element.similarSet($0) }
        for (index, _) in elements.enumerated() {
            guard index != 0 else { continue }
            if index % 4 == 0 {
                elements.insert(Element.ad, at: index)
            }
        }
        self.elements = elements
    }

    mutating func appendNewSimilarGroup(_ similarSets: [[PhotoObject]]) {
        let newSimilarSets: [SimilarPhotosDisplayModel] = similarSets.map { similarSet -> SimilarPhotosDisplayModel in
            let photoModels = similarSet.map { photoObject in PhotoModel(photoObject: photoObject) }
            return SimilarPhotosDisplayModel(photoModels: photoModels)
        }
        var elements = newSimilarSets.map { Element.similarSet($0) }
        for (index, _) in elements.enumerated() {
            guard index != 0 else { continue }
            if index % 4 == 0 {
                elements.insert(Element.ad, at: index)
            }
        }
        self.elements.append(contentsOf: elements)
    }

    mutating func markDelete(_ indexPath: IndexPath, _ photoIndex: Int, _ isOn: Bool) {
//        similarSets[indexPath.row].photoModels[photoIndex].markDelete = isOn
    }

    mutating func swipePhoto(_ indexPath: IndexPath, _ photoIndex: Int) {
//        similarSets[indexPath.row].currentIndex = photoIndex
    }
    
    // Data Source
    func numberOfSections() -> Int {
        return 1
    }

    func numberOfElements(inSection section: Int) -> Int {
        return elements.count
    }

    func element(at indexPath: IndexPath) -> Element {
        return elements[indexPath.row]
    }

}

extension MainViewDisplayModel {

    struct PhotoModel {
        let photoObject: PhotoObject
        var markDelete: Bool

        init(photoObject: PhotoObject, markDelete: Bool = false) {
            self.photoObject = photoObject
            self.markDelete = markDelete
        }
    }

    // This class should contains all the similar photos
    // which photo is the best quality (might be in the future)
    struct SimilarPhotosDisplayModel {
        var photoModels: [PhotoModel]
        var currentIndex = 0
        var setID: String {
            return photoModels[0].photoObject.id
        }
        init(photoModels: [PhotoModel]) {
            self.photoModels = photoModels
        }
    }
}
