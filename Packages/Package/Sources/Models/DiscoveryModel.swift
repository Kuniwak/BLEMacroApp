import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothTestable


public enum DiscoveryModelState<V, E: Error> {
    case notDiscoveredYet
    case discovering([V]?)
    case discovered([V])
    case discoveryFailed(E, [V]?)
    
    
    public var values: [V]? {
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


extension DiscoveryModelState: Equatable where V: Equatable, E: Equatable {
    public static func == (lhs: DiscoveryModelState, rhs: DiscoveryModelState) -> Bool {
        switch (lhs, rhs) {
        case (.notDiscoveredYet, .notDiscoveredYet):
            return true
        case (.discovering(.none), .discovering(.none)):
            return true
        case (.discovering(.some(let lhsValues)), .discovering(.some(let rhsValues))):
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


extension DiscoveryModelState: CustomStringConvertible where V: CustomStringConvertible, E: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDiscoveredYet:
            return ".notDiscoveredYet"
        case .discovering(.none):
            return ".discovering(nil)"
        case .discovering(.some(let values)):
            return ".discovering([\(values.map(\.description).joined(separator: ", "))])"
        case .discovered(let values):
            return ".discovered([\(values.map(\.description).joined(separator: ", "))])"
        case .discoveryFailed(let error, .some(let values)):
            return ".discoveryFailed(\(error.description), [\(values.map(\.description).joined(separator: ", "))])"
        case .discoveryFailed(let error, .none):
            return ".discoveryFailed(\(error.description), nil)"
        }
    }
}


extension DiscoveryModelState: CustomDebugStringConvertible where E: CustomStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notDiscoveredYet:
            return ".notDiscoveredYet"
        case .discovering(.none):
            return ".discovering(nil)"
        case .discovering(.some(let values)):
            return ".discovering([\(values.count) values])"
        case .discovered(let values):
            return ".discovered([\(values.count) values])"
        case .discoveryFailed(let error, .some(let values)):
            return ".discoveryFailed(\(error.description), [\(values.count) values])"
        case .discoveryFailed(let error, .none):
            return ".discoveryFailed(\(error.description), nil)"
        }
    }
}


public protocol DiscoveryModelProtocol<Value, Error>: StateMachine  where State == DiscoveryModelState<Value, Error> {
    associatedtype Value
    associatedtype Error: Swift.Error
    
    var state: State { get async }
    func discover()
}


extension DiscoveryModelProtocol {
    public func eraseToAny() -> AnyDiscoveryModel<Value, Error> {
        AnyDiscoveryModel(self)
    }
}


public actor AnyDiscoveryModel<Value, Error: Swift.Error>: DiscoveryModelProtocol {
    private let base: any DiscoveryModelProtocol<Value, Error>
    
    nonisolated public var initialState: State { base.initialState }
    
    public var state: State {
        get async { await base.state }
    }

    public init(_ base: any DiscoveryModelProtocol<Value, Error>) {
        self.base = base
    }
    
    nonisolated public var stateDidChange: AnyPublisher<DiscoveryModelState<Value, Error>, Never> {
        base.stateDidChange
    }
    
    public func discover() {
        Task { await base.discover() }
    }
}


public actor DiscoveryModel<Value, Failure: Error & CustomStringConvertible>: DiscoveryModelProtocol {
    public typealias Value = Value
    public typealias Error = Failure
    public typealias State = DiscoveryModelState<Value, Failure>
    
    private let peripheral: any PeripheralProtocol
    private let discoverStrategy: (any PeripheralProtocol) async -> Result<[Value], Failure>
    
    public var state: State {
        get async { await stateDidChangeSubject.value }
    }

    private let stateDidChangeSubject: ConcurrentValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    nonisolated public let initialState: State


    public init(
        discoveringBy discoverStrategy: @escaping (any PeripheralProtocol) async -> Result<[Value], Failure>,
        thatTakes peripheral: any PeripheralProtocol
    ) {
        self.peripheral = peripheral
        self.discoverStrategy = discoverStrategy
        
        let initialState: State = .notDiscoveredYet
        self.initialState = initialState
        
        self.stateDidChangeSubject = ConcurrentValueSubject(initialState)
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    public func discover() {
        Task {
            await self.stateDidChangeSubject.change { prev in
                guard !prev.isDiscovering else { return prev }
                return .discovering(prev.values)
            }
            
            switch await self.discoverStrategy(peripheral) {
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
