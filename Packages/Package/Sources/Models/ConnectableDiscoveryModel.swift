import Combine
import CoreBluetooth
import ModelFoundation
import ConcurrentCombine


public struct ConnectableDiscoveryModelState<Value, Failure: Error> {
    public let discovery: DiscoveryModelState<Value, Failure>
    public let connection: ConnectionModelState
    public let discoveryRequested: Bool
    
    
    public init(
        discovery: DiscoveryModelState<Value, Failure>,
        connection: ConnectionModelState,
        discoveryRequested: Bool
    ) {
        self.discovery = discovery
        self.connection = connection
        self.discoveryRequested = discoveryRequested
    }
}


extension ConnectableDiscoveryModelState where Value: CustomStringConvertible, Failure: CustomStringConvertible {
    public var description: String {
        "(discovery: \(discovery.description), connection: \(connection.description), discoveryRequested: \(discoveryRequested))"
    }
}


extension ConnectableDiscoveryModelState where Value: CustomDebugStringConvertible, Failure: CustomDebugStringConvertible {
    public var description: String {
        "(discovery: \(discovery.debugDescription), connection: \(connection.debugDescription), discoveryRequested: \(discoveryRequested))"
    }
}


public protocol ConnectableDiscoveryModelProtocol<Value, Failure>: StateMachineProtocol where State == ConnectableDiscoveryModelState<Value, Failure> {
    associatedtype Value
    associatedtype Failure: Error
    
    nonisolated var connection: any ConnectionModelProtocol { get }
    nonisolated func discover()
    nonisolated func connect()
    nonisolated func disconnect()
}


extension ConnectableDiscoveryModelProtocol {
    nonisolated public func eraseToAny() -> AnyConnectableDiscoveryModel<Value, Failure> {
        AnyConnectableDiscoveryModel(self)
    }
}


public final actor AnyConnectableDiscoveryModel<Value, Failure: Error>: ConnectableDiscoveryModelProtocol {
    public typealias Value = Value
    public typealias Failure = Failure
    
    private let base: any ConnectableDiscoveryModelProtocol<Value, Failure>
    
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    nonisolated public var connection: any ConnectionModelProtocol { base.connection }

    
    public init(_ base: any ConnectableDiscoveryModelProtocol<Value, Failure>) {
        self.base = base
    }
    
    
    nonisolated public func discover() {
        base.discover()
    }
    
    
    nonisolated public func connect() {
        base.connect()
    }
    
    
    nonisolated public func disconnect() {
        base.disconnect()
    }
}


extension AnyConnectableDiscoveryModel where Value: CustomStringConvertible, Failure: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}


public final actor ConnectableDiscoveryModel<Value, Failure: Error>: ConnectableDiscoveryModelProtocol {
    public typealias Value = Value
    public typealias Failure = Failure

    nonisolated private let discovery: any DiscoveryModelProtocol<Value, Failure>
    nonisolated public let connection: any ConnectionModelProtocol
    nonisolated private let discoveryRequestedSubject: ConcurrentValueSubject<Bool, Never>
    
    nonisolated public var state: State {
        ConnectableDiscoveryModelState(
            discovery: discovery.state,
            connection: connection.state,
            discoveryRequested: discoveryRequestedSubject.value
        )
    }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        discoveringBy discovery: any DiscoveryModelProtocol<Value, Failure>,
        connectingBy connection: any ConnectionModelProtocol
    ) {
        self.discovery = discovery
        self.connection = connection
        
        let discoveryRequestedSubject = ConcurrentValueSubject<Bool, Never>(false)
        self.discoveryRequestedSubject = discoveryRequestedSubject
        
        let stateDidChange = discovery.stateDidChange
            .combineLatest(connection.stateDidChange, discoveryRequestedSubject)
            .map { discoveryState, connection, discoveryRequested in
                ConnectableDiscoveryModelState(
                    discovery: discoveryState,
                    connection: connection,
                    discoveryRequested: discoveryRequested
                )
            }
        
        self.stateDidChange = stateDidChange.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        stateDidChange
            .sink { state in
                Task {
                    let shouldDiscover = state.discoveryRequested && !state.discovery.isDiscovering && state.connection.isConnected
                    if shouldDiscover {
                        await discoveryRequestedSubject.change { _ in false }
                        discovery.discover()
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        let cancellables = mutableCancellables
        Task { await self.store(cancellables: cancellables) }
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables.formUnion(cancellables)
    }
    
    
    nonisolated public func discover() {
        Task {
            if connection.state.isConnected {
                discovery.discover()
            } else {
                await requestDiscovery()
                connection.connect()
            }
        }
    }
    
    
    nonisolated public func connect() {
        connection.connect()
    }
    
    
    nonisolated public func disconnect() {
        connection.disconnect()
    }
    
    
    private func requestDiscovery() async {
        await discoveryRequestedSubject.change { _ in true }
    }
}
