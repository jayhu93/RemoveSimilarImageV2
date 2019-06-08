//
//  BehaviorEventEmittable.swift
//  RemoveSimilarImages
//
//  Created by Yupin Hu on 5/25/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result
import ReactiveSwift

protocol BehaviorEventEmittable {
    associatedtype BehaviorEvent
    var emitter: EventEmitter<BehaviorEvent> { get }
    func observe(_ f: @escaping (BehaviorEvent) -> Void)
}

extension BehaviorEventEmittable {
    func observe(_ f: @escaping (BehaviorEvent) -> Void) {
        emitter.output.observeValues(f)
    }
}

extension BehaviorEventEmittable where Self: NSObject & Reusable {
    func observe(_ f: @escaping (BehaviorEvent) -> Void) {
        emitter.output.take(until: reactive.prepareForReuse).observeValues(f)
    }
}

extension BehaviorEventEmittable where Self: AnyObject {
    @discardableResult
    func forward<P: BehaviorEventEmittable & AnyObject>(to parent: P, transform: @escaping (BehaviorEvent) -> P.BehaviorEvent?) -> Self {
        observe { [weak parent] event in
            guard let parentEvent = transform(event) else { return }
            parent?.emitter.emit(event: parentEvent)
        }
        return self
    }
    @discardableResult
    func forward<P: BehaviorEventEmittable & AnyObject>(to parent: P) -> Self where BehaviorEvent: Convertible, BehaviorEvent.Argument == Void, BehaviorEvent.Target == P.BehaviorEvent {
        return forward(to: parent) { $0.convert() }
    }
}

struct EventEmitter<Event> {
    private let eventPipe = Signal<Event, NoError>.pipe()

    init() {}

    func emit(event: Event) {
        eventPipe.input.send(value: event)
    }

    var output: Signal<Event, NoError> {
        return eventPipe.output
    }
}

protocol Convertible {
    associatedtype Target
    associatedtype Argument
    func convert(with argument: Argument) -> Target?
}

extension Convertible where Argument == Void {
    func convert() -> Target? {
        return convert(with: ())
    }
}
