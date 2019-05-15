//
//  PaginationService.swift
//  RemoveSimilarImages
//
//  Created by Yupin Hu on 5/14/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import ReactiveSwift

protocol RequestType {
    
}

final class PaginationService<Value, Request: RequestType> {
    typealias Dependency = PhotoLibraryServiceType

    struct State {
        var isRefreshing: Bool = false
        var isPaginating: Bool = false
        fileprivate var nextRequest: Request?
    }

}
