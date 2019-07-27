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
        let elements = similarSets.map { Element.similarSet($0) }
        self.elements = elements
    }

    init(_ simialrSetObjects: [SimilarSetObject]) {
        let newSimilarSets = simialrSetObjects.map {
            SimilarPhotosDisplayModel(
                photoModels: $0.photoObjects.map { PhotoModel(photoObject: $0) }, setID: $0.id
            )
        }
        let elements = newSimilarSets.map { Element.similarSet($0) }
        self.elements = elements
    }

    mutating func removeAll() {
        elements.removeAll()
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
        let setID: String
        init(photoModels: [PhotoModel], setID: String) {
            self.photoModels = photoModels
            self.setID = setID
        }
    }
}
