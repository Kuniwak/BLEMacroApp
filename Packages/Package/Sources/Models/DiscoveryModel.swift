import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothTestable


public enum DiscoveryModelState<ID: Hashable, S, M: StateMachine<S> & Identifiable<ID>, E: Error> {
    case notDiscoveredYet
    case discovering(StateMachineArray<ID, S, M>?)
    case discovered(StateMachineArray<ID, S, M>)
    case discoveryFailed(E, StateMachineArray<ID, S, M>?)
    
    
    public var values: StateMachineArray<ID, S, M>? {
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


extension DiscoveryModelState: CustomStringConvertible where E: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDiscoveredYet:
            return ".notDiscoveredYet"
        case .discovering(.none):
            return ".discovering(nil)"
        case .discovering(.some):
            return ".discovering([...])"
        case .discovered:
            return ".discovered([...])"
        case .discoveryFailed(let error, .some):
            return ".discoveryFailed(\(error.description), [...])"
        case .discoveryFailed(let error, .none):
            return ".discoveryFailed(\(error.description), nil)"
        }
    }
}


public protocol DiscoveryModelProtocol<ID, S, M, Error>: StateMachine where State == DiscoveryModelState<ID, S, M, Error> {
    associatedtype ID: Hashable
    associatedtype S
    associatedtype M: StateMachine<S> & Identifiable<ID>
    associatedtype Error: Swift.Error
    
    var state: State { get async }
    func discover()
}


extension DiscoveryModelProtocol {
    public func eraseToAny() -> AnyDiscoveryModel<ID, S, M, Error> {
        AnyDiscoveryModel(self)
    }
}


public actor AnyDiscoveryModel<ID: Hashable, S, M: StateMachine<S> & Identifiable<ID>, Error: Swift.Error>: DiscoveryModelProtocol {
    private let base: any DiscoveryModelProtocol<ID, S, M, Error>
    
    nonisolated public var initialState: State { base.initialState }
    
    public var state: State {
        get async { await base.state }
    }

    public init(_ base: any DiscoveryModelProtocol<ID, S, M, Error>) {
        self.base = base
    }
    
    nonisolated public var stateDidChange: AnyPublisher<DiscoveryModelState<ID, S, M, Error>, Never> {
        base.stateDidChange
    }
    
    public func discover() {
        Task { await base.discover() }
    }
}


public actor DiscoveryModel<ID: Hashable, S, M: StateMachine<S> & Identifiable<ID>, Failure: Error & CustomStringConvertible>: DiscoveryModelProtocol {
    public typealias ID = ID
    public typealias S = S
    public typealias M = M
    public typealias State = DiscoveryModelState<ID, S, M, Failure>
    
    private let discoverStrategy: () async -> Result<[M], Failure>
    
    public var state: State {
        get async { await stateDidChangeSubject.value }
    }

    private let stateDidChangeSubject: ConcurrentValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    nonisolated public let initialState: State


    public init(discoveringBy discoverStrategy: @escaping () async -> Result<[M], Failure>) {
        let initialState: State = .notDiscoveredYet
        self.initialState = initialState
        
        self.stateDidChangeSubject = ConcurrentValueSubject(initialState)
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
                    return .discovered(StateMachineArray(values))
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
