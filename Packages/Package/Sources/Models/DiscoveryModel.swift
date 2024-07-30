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
    
    
    public var isFailed: Bool {
        switch self {
        case .discoveryFailed:
            return true
        case .discovered, .notDiscoveredYet, .discovering:
            return false
        }
    }
}


extension DiscoveryModelState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDiscoveredYet:
            return ".notDiscoveredYet"
        case .discovering(.none):
            return ".discovering(nil)"
        case .discovering(.some(let models)):
            return ".discovering([\(models.map(String.init(describing:)).joined(separator: ", "))])"
        case .discovered(let models):
            return ".discovered([\(models.map(String.init(describing:)).joined(separator: ", "))])"
        case .discoveryFailed(let error, .some(let models)):
            return ".discoveryFailed(\(error), [\(models.map(String.init(describing:)).joined(separator: ", "))])"
        case .discoveryFailed(let error, .none):
            return ".discoveryFailed(\(error), nil)"
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
    
    nonisolated func discover()
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
    
    nonisolated public func discover() {
        base.discover()
    }
}


// ```marmaid
// stateDiagram-v2
//     state ".notDiscoveredYet" as notDiscoveredYet
//     state ".discovering(nil)" as discovering_nil
//     state ".discovered([Value])" as discovered
//     state ".discoveryFailed(Failure, nil)" as discoveryFailed_nil
//     state ".discovering([Value])" as discovering_some
//     state ".discoveryFailed(Failure, [Value])" as discoveryFailed_some
//
//     [*] --> notDiscoveredYet: T1
//     notDiscoveredYet --> discovering_nil: T2 discover
//     discovering_nil --> discovering_nil: T3 discover
//     discovering_nil --> discovered: T4 tau
//     discovering_nil --> discoveryFailed_nil: T5 tau
//     discoveryFailed_nil --> discovering_nil: T6 discover
//     discovered --> discovering_some: T7 discover
//     discovering_some --> discovering_some: T8 discover
//     discovering_some --> discovered: T9 tau
//     discovering_some --> discoveryFailed_some: T10 tau
//     discoveryFailed_some --> discovering_some: T11 discover
// ```
public final actor DiscoveryModel<Value, Failure: Error>: DiscoveryModelProtocol {
    private let discoverStrategy: () async -> Result<[Value], Failure>
    
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated private let stateDidChangeSubject: ConcurrentValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    

    public init(discoveringBy discoverStrategy: @escaping () async -> Result<[Value], Failure>) {
        self.stateDidChangeSubject = ConcurrentValueSubject(.notDiscoveredYet) // T1
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        self.discoverStrategy = discoverStrategy
    }
    
    
    nonisolated public func discover() {
        Task { await discoverInternal() }
    }
    
    
    private func discoverInternal() async {
        await self.stateDidChangeSubject.change { prev in
            guard !prev.isDiscovering else { return prev } // T3, T8
            return .discovering(prev.values) // T2, T6, T7, T11
        }
        
        switch await self.discoverStrategy() {
        case .success(let values):
            await self.stateDidChangeSubject.change { prev in
                guard case .discovering = prev else { return prev }
                return .discovered(values) // T4, T9
            }
        case .failure(let error):
            await self.stateDidChangeSubject.change { prev in
                guard case .discovering = prev else { return prev }
                return .discoveryFailed(error, prev.values) // T5, T10
            }
        }
    }
}
