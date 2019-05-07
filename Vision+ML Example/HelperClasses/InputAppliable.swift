import Foundation
import Result
import ReactiveSwift

protocol InputAppliable {
    associatedtype Input
    func apply(input: Input)
}

extension InputAppliable {
    func applied(input: Input) -> Self {
        apply(input: input)
        return self
    }
}
