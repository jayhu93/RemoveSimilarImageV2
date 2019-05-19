//
//  PaginationService.swift
//  RemoveSimilarImages
//
//  Created by Yupin Hu on 5/14/19.
//  Copyright © 2019 Apple. All rights reserved.
//



import Foundation
import ReactiveSwift

class Message {

}

protocol RequestType {
    associatedtype Response: Message
}

final class PaginationService<Value, Request: RequestType> {
    typealias Dependency = PhotoLibraryServiceType

    struct State {
        var isRefreshing: Bool = false
        var isPaginating: Bool = false
        fileprivate var nextRequest: Request?
    }

    struct RefreshOptions {
        var clearOnRequest = false
    }

    let valueProperty: Property<Value>
    let stateProperty: Property<State>

    private let _valueProperty: MutableProperty<Value>
    private let _refresh: (Request, RefreshOptions) -> SignalProducer<Request.Response, Error>
    private let _paginate: () -> SignalProducer<Request.Response, ActionError<Error>>
    private let lifetime = Lifetime.make()

    enum AccumulateAction {
        case clear
        case refresh(Request.Response)
        case paginate(Request.Response)
    }

    init(dependency: Dependency,
         nextRequestTransformer: @escaping (Request, Request.Response) -> Request?,
         initialValue: Value,
         reduceValue: @escaping (inout Value, AccumulateAction) -> Void) {

        let photoLibraryService = dependency

        let valueProperty = MutableProperty(initialValue)
        self.valueProperty = Property(valueProperty)
        _valueProperty = valueProperty

        let stateProperty = MutableProperty(State())
        self.stateProperty = stateProperty.map { $0 }

        let refreshAction = Action<(Request, RefreshOptions), (Request, Request.Response), Error> { request, options in
            if options.clearOnRequest { valueProperty.modify { reduceValue(&$0, .clear) } }
            return photoLibraryService.response(from: request).map { (request, $0) }
        }


        let paginateAction = Action<Void, (Request, Request.Response), Error>(
            unwrapping: stateProperty.map { $0.nextRequestIfEnabled },
            execute: { request in photoLibraryService.response(from: request).map { (request, $0) } }
        )

        // MARK: Action

        let refreshDisposable = Atomic<Disposable?>(nil)
        let paginateDisposable = Atomic<Disposable?>(nil)
        _refresh = { request, options in
            return SignalProducer { observer, lifetime in
                refreshDisposable.modify {
                    $0?.dispose()
                    paginateDisposable.withValue { $0?.dispose() }
                    let disposable = refreshAction.apply((request, options)).map { $1 }
                        .flatMapError { error in
                            switch error {
                            case .producerFailed(let error): return SignalProducer(error: error)
                            case .disabled:
                                assertionFailure("Refresh should be always enabled")
                            }
                        }
                        .start(observer)
                    $0 = disposable
                    lifetime += disposable
                }
            }
        }

        _paginate = {
            return SignalProducer { observer, lifetime in
                paginateDisposable.modify {
                    guard paginateAction.isEnabled.value else {
                        observer.send(error: .disabled)
                        return
                    }
                    let disposable = paginateAction
                        .apply()
                        .map { $1 }
                        .start(observer)
                    $0 = disposable
                    lifetime += disposable
                }

            }
        }

        // MARK: Value binding

        refreshAction.values.observeValues { _, response in
            valueProperty.modify { reduceValue(&$0, .paginate(response)) }
        }

        // MARK: State binding

        Signal
            .merge(
                refreshAction.values,
                paginateAction.values
            )
            .map(nextRequestTransformer)
            .observeValues { request in
                stateProperty.modify { $0.nextRequest = request } }

        refreshAction.isExecuting.signal
            .observeValues { isExecuting in stateProperty.modify { $0.isRefreshing = isExecuting } }

        paginateAction.isExecuting.signal
            .onserveValues { isExexuting in stateProperty.modify { $0.isPaginating = isExexuting } }

        errorSignal = Signal.merge(refreshAction.errors, paginateAction.errors)

    }

}
