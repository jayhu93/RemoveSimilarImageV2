//
//  ClearTests.swift
//  ClearTests
//
//  Created by YupinHuPro on 5/5/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import XCTest
import RealmSwift
@testable import Clear

class ClearTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testArrayComparision() {
        let photoObject = PhotoObject()
        photoObject.similarArray.append(objectsIn: [1, 2, 3, 4, 5])

        let trueArray = [1, 2, 3, 4, 5]
        let falseArray = [Int]()
        let falseArray2 = [1, 3, 0]
        let trueArray2 = [5, 3, 4, 1, 2]

        let trueResult = photoObject.containsElementsFrom(anotherArray: trueArray)
        let trueResult2 = photoObject.containsElementsFrom(anotherArray: trueArray2)

        let falseResult = photoObject.containsElementsFrom(anotherArray: falseArray)
        let falseResult2 = photoObject.containsElementsFrom(anotherArray: falseArray2)

        XCTAssertTrue(trueResult)
        XCTAssertTrue(trueResult2)
        XCTAssertFalse(falseResult)
        XCTAssertFalse(falseResult2)
    }
}
