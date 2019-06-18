//
//  Objects.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 4/29/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import RealmSwift

class SimilarSetObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var timestamp: Date = Date()
    @objc dynamic var showSet: Bool = true
    let photoObjects = List<PhotoObject>()
    
    func ableInsertObject(_ photoObject: PhotoObject) -> Bool {
        guard !photoObjects.contains(photoObject) else { return false }
        guard let firstObject = photoObjects.first else { return false }
        return firstObject.containsElementsFrom(anotherArray: Array(photoObject.similarArray))
    }
    
    override static func primaryKey() -> String {
        return "id"
    }
}

class PhotoObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var timestamp = Date()
    var grouped: Bool = false
    let similarArray = List<Int>()

    override static func primaryKey() -> String {
        return "id"
    }

    // given 2 arrays, return ture if they have at least 3 elements that are the same
    // below is the brute force way, with a run time of O(n^2)

    // let have them array sorted with ascending order
    // keep two counters

    // counter1 loops through array1
    // counter2 loops through array2

    func containsElementsFrom(anotherArray: [Int]) -> Bool {
        let array1 = Array(similarArray).sorted()
        let array2 = anotherArray.sorted()

        var counter = 0
        var counter1 = 0
        var counter2 = 0

        while counter1 < array1.count && counter2 < array2.count {
            if array1[counter1] == array2[counter2] {
                counter += 1
                if counter >= 3 {
                    return true
                }
                counter1 += 1
                counter2 += 1
            } else if array1[counter1] > array2[counter2] {
                // increment the lower counter
                guard counter <= array2.count else { return false }
                counter2 += 1
            } else if array1[counter1] < array2[counter2] {
                guard counter <= array1.count else { return false }
                counter1 += 1
            }
        }
        return false
    }
}
