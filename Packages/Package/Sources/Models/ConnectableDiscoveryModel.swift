import Combine
import CoreBluetooth
import ModelFoundation


public struct ConnectableDiscoveryModelState<Value, Failure: Error> {
    public let discovery: DiscoveryModelState<Value, Failure>
    public let connection: ConnectionModelState
    
    
    public init(discovery: DiscoveryModelState<Value, Failure>, connection: ConnectionModelState) {
        self.discovery = discovery
        self.connection = connection
    }
}


extension ConnectableDiscoveryModelState where Value: CustomStringConvertible, Failure: CustomStringConvertible {
    public var description: String {
        "(discovery: \(discovery.description), connection: \(connection.description))"
    }
}


extension ConnectableDiscoveryModelState where Value: CustomDebugStringConvertible, Failure: CustomDebugStringConvertible {
    public var description: String {
        "(discovery: \(discovery.debugDescription), connection: \(connection.debugDescription))"
    }
}


public protocol ConnectableDiscoveryModelProtocol<Value, Failure>: StateMachineProtocol where State == ConnectableDiscoveryModelState<Value, Failure> {
    associatedtype Value
    associatedtype Failure: Error
    
    nonisolated var connection: any ConnectionModelProtocol { get }
    func discover()
    func connect()
    func disconnect()
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
    
    
    public func discover() {
        Task { await base.discover() }
    }
    
    
    public func connect() {
        Task { await base.connect() }
    }
    
    
    public func disconnect() {
        Task { await base.disconnect() }
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
    private var discoveryRequested = false
    
    nonisolated public var state: State {
        ConnectableDiscoveryModelState(
            discovery: discovery.state,
            connection: connection.state
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
        
        let stateDidChange = discovery.stateDidChange
            .combineLatest(connection.stateDidChange)
            .map { discoveryState, connection in
                ConnectableDiscoveryModelState(
                    discovery: discoveryState,
                    connection: connection
                )
            }
        
        self.stateDidChange = stateDidChange.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        stateDidChange
            .sink { [weak self] state in
                guard let self = self else { return }
                
                Task {
                    guard await self.shouldDiscovery(state) else { return }
                    await self.discovery.discover()
                }
            }
            .store(in: &mutableCancellables)
        
        let cancellables = mutableCancellables
        Task { await self.store(cancellables: cancellables) }
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables.formUnion(cancellables)
    }
    
    
    public func discover() {
        Task {
            if connection.state.isConnected {
                await discovery.discover()
            } else {
                self.discoveryRequested = true
                await connection.connect()
            }
        }
    }
    
    
    public func connect() {
        Task { await connection.connect() }
    }
    
    
    public func disconnect() {
        Task { await connection.disconnect() }
    }
    
    
    private func shouldDiscovery(_ state: ConnectableDiscoveryModelState<Value, Failure>) -> Bool {
        let result = discoveryRequested && !state.discovery.isDiscovering && state.connection.isConnected
        if result {
            discoveryRequested = false
        }
        return result
    }
}
