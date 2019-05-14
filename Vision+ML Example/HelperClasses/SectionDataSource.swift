//
//  SectionDataSource.swift
//  RemoveSimilarImages
//
//  Created by Yupin Hu on 5/13/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

protocol SectionedDataSource {
    func numberOfSections() -> Int
    func numberOfElements(inSection section: Int) -> Int
}
