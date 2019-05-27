//
//  MainViewDisplayModel.swift
//  RemoveSimilarImages
//
//  Created by Yupin Hu on 5/12/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

struct MainViewDisplayModel {

    var similarSets = [SimilarPhotosDisplayModel]()


    init(similarSets: [SimilarPhotosDisplayModel] = []) {
        self.similarSets = similarSets
    }

    mutating func appendNewSimilarGroup(_ similarSets: [[PhotoObject]]) {
        let newSimilarSets: [SimilarPhotosDisplayModel] = similarSets.map { similarSet -> SimilarPhotosDisplayModel in
            let photoModels = similarSet.map { photoObject in PhotoModel(photoObject: photoObject) }
            return SimilarPhotosDisplayModel(photoModels: photoModels)
        }
        self.similarSets.append(contentsOf: newSimilarSets)
    }

    mutating func markDelete(_ indexPath: IndexPath, _ photoIndex: Int, _ isOn: Bool) {
        similarSets[indexPath.row].photoModels[photoIndex].markDelete = isOn
    }

    mutating func swipePhoto(_ indexPath: IndexPath, _ photoIndex: Int) {
        similarSets[indexPath.row].currentIndex = photoIndex
    }

    mutating func updateSimilarSetObjects(_ simialrSetObjects: [SimilarSetObject]) {
        let newSimilarSets = simialrSetObjects.map {
            SimilarPhotosDisplayModel(
                photoModels: $0.photoObjects.map { PhotoModel(photoObject: $0) }
            )
        }
        similarSets = newSimilarSets
    }
    
    // Data Source
    func numberOfSections() -> Int {
        return 1
    }

    func numberOfElements(inSection section: Int) -> Int {
        return similarSets.count
    }

    func element(at indexPath: IndexPath) -> SimilarPhotosDisplayModel {
        return similarSets[indexPath.row]
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
        init(photoModels: [PhotoModel]) {
            self.photoModels = photoModels
        }
    }
}
