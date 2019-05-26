//
//  MainViewDisplayModel.swift
//  RemoveSimilarImages
//
//  Created by Yupin Hu on 5/12/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

struct MainViewDisplayModel {

    enum ItemType {
        case similarPhotos(SimilarPhotosDisplayModel)
    }

    struct Section {
        private(set) var items: [ItemType]

        mutating func append(_ newElements: [ItemType]) {
            items.append(contentsOf: newElements)
        }
    }

    var sections: [Section] // there is only one giant section for now

    init(sections: [Section] = []) {
        self.sections = sections
    }

    mutating func appendNewSimilarGroup(_ similarSets: [[PhotoObject]]) {
        var newItems = [ItemType]()
        for similarSet in similarSets {
            let photoModels = similarSet.map { PhotoModel.init(photoObject: $0) }
            let displayModel = SimilarPhotosDisplayModel(photoModels: photoModels)
            let itemType = ItemType.similarPhotos(displayModel)
            newItems.append(itemType)
        }
        let section = Section(items: newItems)
        sections.append(section)
    }

    // Data Source
    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfElements(inSection section: Int) -> Int {
        return sections[section].items.count
    }

    func element(at indexPath: IndexPath) -> MainViewDisplayModel.ItemType {
        return sections[indexPath.section].items[indexPath.row]
    }

}

extension MainViewDisplayModel {

    struct PhotoModel {
        let photoObject: PhotoObject
        let markDelete: Bool

        init(photoObject: PhotoObject, markDelete: Bool = false) {
            self.photoObject = photoObject
            self.markDelete = markDelete
        }
    }

    // This class should contains all the similar photos
    // which photo is the best quality (might be in the future)
    struct SimilarPhotosDisplayModel {
        let photoModels: [PhotoModel]
        init(photoModels: [PhotoModel]) {
            self.photoModels = photoModels
        }
    }
}
