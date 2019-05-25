//
//  SimilarSetActionView.swift
//  RemoveSimilarImages
//
//  Created by Yupin Hu on 5/25/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit

final class SimilarSetActionView: NibInstantiableView {

    var emitter = EventEmitter<BehaviorEvent>()

    @IBAction private func removeAll(_ sender: UIButton) {
        emitter.emit(event: .removeAll)
    }
    @IBAction private func removeSelected(_ sender: UIButton) {
        emitter.emit(event: .removeSelected)
    }
    @IBAction private func keepAll(_ sender: UIButton) {
        emitter.emit(event: .keepAll)
    }

}

extension SimilarSetActionView: BehaviorEventEmittable {
    enum BehaviorEvent: Equatable {
        case removeAll
        case removeSelected
        case keepAll
    }
}
