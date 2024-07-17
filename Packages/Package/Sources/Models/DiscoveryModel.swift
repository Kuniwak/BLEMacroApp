import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothTestable
import ModelFoundation


public enum DiscoveryModelState<Value, Failure: Error> {
    case notDiscoveredYet
    case discovering([Value]?)
    case discovered([Value])
    case discoveryFailed(Failure, [Value]?)
    
    
    public var values: [Value]? {
        switch self {
        case .discovered(let values), .discovering(.some(let values)), .discoveryFailed(_, .some(let values)):
            return values
        case .discovering(nil), .discoveryFailed(_, nil), .notDiscoveredYet:
            return nil
        }
    }
    
    
    public var isDiscovering: Bool {
        switch self {
        case .discovering:
            return true
        case .discovered, .notDiscoveredYet, .discoveryFailed:
            return false
        }
    }
}


extension DiscoveryModelState: CustomStringConvertible where Value: CustomStringConvertible, Failure: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDiscoveredYet:
            return ".notDiscoveredYet"
        case .discovering(.none):
            return ".discovering(nil)"
        case .discovering(.some(let models)):
            return ".discovering([\(models.map(\.description).joined(separator: ", "))])"
        case .discovered(let models):
            return ".discovered([\(models.map(\.description).joined(separator: ", "))])"
        case .discoveryFailed(let error, .some(let models)):
            return ".discoveryFailed(\(error.description), [\(models.map(\.description).joined(separator: ", "))])"
        case .discoveryFailed(let error, .none):
            return ".discoveryFailed(\(error.description), nil)"
        }
    }
}


extension DiscoveryModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notDiscoveredYet:
            return ".notDiscoveredYet"
        case .discovering(.none):
            return ".discovering(nil)"
        case .discovering(.some(let models)):
            return ".discovering([\(models.count) entries])"
        case .discovered(let models):
            return ".discovered([\(models.count) entries])"
        case .discoveryFailed(_, .some(let models)):
            return ".discoveryFailed(error, [\(models.count) entries])"
        case .discoveryFailed(_, .none):
            return ".discoveryFailed(error, nil)"
        }
    }
}


extension DiscoveryModelState: Equatable where Value: Equatable, Failure: Equatable {
    public static func == (lhs: DiscoveryModelState, rhs: DiscoveryModelState) -> Bool {
        switch (lhs, rhs) {
        case (.notDiscoveredYet, .notDiscoveredYet):
            return true
        case (.discovering(let lhsValues), .discovering(let rhsValues)):
            return lhsValues == rhsValues
        case (.discovered(let lhsValues), .discovered(let rhsValues)):
            return lhsValues == rhsValues
        case (.discoveryFailed(let lhsError, let lhsValues), .discoveryFailed(let rhsError, let rhsValues)):
            return lhsError == rhsError && lhsValues == rhsValues
        default:
            return false
        }
    }
}


public protocol DiscoveryModelProtocol<Value, Failure>: StateMachineProtocol where State == DiscoveryModelState<Value, Failure> {
    associatedtype Value
    associatedtype Failure: Error
    
    func discover()
}


extension DiscoveryModelProtocol {
    public func eraseToAny() -> AnyDiscoveryModel<Value, Failure> {
        AnyDiscoveryModel(self)
    }
}


public final actor AnyDiscoveryModel<Value, Failure: Error>: DiscoveryModelProtocol {
    private let base: any DiscoveryModelProtocol<Value, Failure>
    
    nonisolated public var state: State { base.state }

    public init(_ base: any DiscoveryModelProtocol<Value, Failure>) {
        self.base = base
    }
    
    nonisolated public var stateDidChange: AnyPublisher<DiscoveryModelState<Value, Failure>, Never> {
        base.stateDidChange
    }
    
    public func discover() {
        Task { await base.discover() }
    }
}


public final actor DiscoveryModel<Value, Failure: Error>: DiscoveryModelProtocol {
    private let discoverStrategy: () async -> Result<[Value], Failure>
    
    nonisolated public var state: State { stateDidChangeSubject.projected }
    nonisolated private let stateDidChangeSubject: ProjectedValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    

    public init(discoveringBy discoverStrategy: @escaping () async -> Result<[Value], Failure>) {
        self.stateDidChangeSubject = ProjectedValueSubject(.notDiscoveredYet)
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        self.discoverStrategy = discoverStrategy
    }
    
    
    public func discover() {
        Task {
            await self.stateDidChangeSubject.change { prev in
                guard !prev.isDiscovering else { return prev }
                return .discovering(prev.values)
            }
            
            switch await self.discoverStrategy() {
            case .success(let values):
                await self.stateDidChangeSubject.change { prev in
                    guard case .discovering = prev else { return prev }
                    return .discovered(values)
                }
            case .failure(let error):
                await self.stateDidChangeSubject.change { prev in
                    guard case .discovering = prev else { return prev }
                    return .discoveryFailed(error, prev.values)
                }
            }
        }
    }
}
