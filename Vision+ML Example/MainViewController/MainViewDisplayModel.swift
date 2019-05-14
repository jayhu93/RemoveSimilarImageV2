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
    }

    let sections: [Section] // each section contains 20 groups of the simiar photos

    init(sections: [Section] = []) {
        self.sections = sections
    }

    mutating func appendNewSimilarGroup(_ photos: [PhotoObject]) {
        // check if last section has 20 items
        // if yes, make a new section, append photos in the new section and append the new section

        // if no, mutate this last section and append it in that section
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
    // This class should contains all the similar photos
    // which photo is the best quality (might be in the future)
    struct SimilarPhotosDisplayModel {
        let photos: [PhotoObject]

        init(photos: [PhotoObject]) {
            self.photos = photos
        }
    }
}
