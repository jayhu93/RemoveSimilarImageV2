import Foundation
import ReactiveSwift

public enum SchedulerProviderSchedulerType {
    case immediate
    case ui
}

public enum SchedulerProviderDateSchedulerType {
    public enum Queue {
        case main
        case background(DispatchQoS, name: String, DispatchQueue?)
        public init(_ qos: DispatchQoS = .default, name: String = "com.mercari.DoubleCore.SchedulerProviderType", targetQueue: DispatchQueue? = nil) {
            self = .background(qos, name: name, targetQueue)
        }
    }
    case queue(Queue)
}

public protocol SchedulerProviderType {
    func scheduler(with type: SchedulerProviderSchedulerType) -> Scheduler
    func scheduler(with type: SchedulerProviderDateSchedulerType) -> DateScheduler
}

public final class SchedulerProvider: SchedulerProviderType {
    public static let shared = SchedulerProvider()

    public func scheduler(with type: SchedulerProviderSchedulerType) -> Scheduler {
        switch type {
        case .immediate: return ImmediateScheduler()
        case .ui: return UIScheduler()
        }
    }

    public func scheduler(with type: SchedulerProviderDateSchedulerType) -> DateScheduler {
        switch type {
        case .queue(let queue):
            switch queue {
            case .main:
                return QueueScheduler.main
            case .background(let qos, let name, let targetQueue):
                return QueueScheduler(qos: qos, name: name, targeting: targetQueue)
            }
        }
    }
}
