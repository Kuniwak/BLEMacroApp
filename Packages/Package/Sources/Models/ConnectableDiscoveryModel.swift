import Combine
import CoreBluetooth


public struct ConnectableDiscoveryModelState<ID: Hashable, S, M: StateMachine<S> & Identifiable<ID>, Failure: Error> {
    public let discovery: DiscoveryModelState<ID, S, M, Failure>
    public let connection: ConnectionModelState
    
    
    public init(discovery: DiscoveryModelState<ID, S, M, Failure>, connection: ConnectionModelState) {
        self.discovery = discovery
        self.connection = connection
    }
}


public protocol ConnectableDiscoveryModelProtocol<ID, S, M, Failure>: StateMachine where State == ConnectableDiscoveryModelState<ID, S, M, Failure> {
    associatedtype ID: Hashable
    associatedtype S
    associatedtype M: StateMachine<S> & Identifiable<ID>
    associatedtype Failure: Error
    var state: State { get async }
    
    func discover()
    func connect()
    func disconnect()
}


extension ConnectableDiscoveryModelProtocol {
    nonisolated public func eraseToAny() -> AnyConnectableDiscoveryModel<ID, S, M, Failure> {
        AnyConnectableDiscoveryModel(self)
    }
}


public actor AnyConnectableDiscoveryModel<ID: Hashable, S, M: StateMachine<S> & Identifiable<ID>, Failure: Error>: ConnectableDiscoveryModelProtocol {
    public typealias ID = ID
    public typealias S = S
    public typealias M = M
    public typealias Failure = Failure
    public typealias State = ConnectableDiscoveryModelState<ID, S, M, Failure>
    
    private let base: any ConnectableDiscoveryModelProtocol<ID, S, M, Failure>
    
    public var state: State {
        get async { await base.state }
    }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    nonisolated public var initialState: State { base.initialState }

    
    public init(_ base: any ConnectableDiscoveryModelProtocol<ID, S, M, Failure>) {
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


public actor ConnectableDiscoveryModel<ID: Hashable, S, M: StateMachine<S> & Identifiable<ID>, Failure: Error>: ConnectableDiscoveryModelProtocol {
    public typealias ID = ID
    public typealias S = S
    public typealias M = M
    public typealias Failure = Failure
    public typealias State = ConnectableDiscoveryModelState<ID, S, M, Failure>

    private let discovery: any DiscoveryModelProtocol<ID, S, M, Failure>
    private let connection: any ConnectionModelProtocol
    private var discoveryRequested = false
    
    public var state: State {
        get async {
            ConnectableDiscoveryModelState(
                discovery: await discovery.state,
                connection: await connection.state
            )
        }
    }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    private var cancellables = Set<AnyCancellable>()
    
    nonisolated public var initialState: State {
        ConnectableDiscoveryModelState(
            discovery: discovery.initialState,
            connection: connection.initialState
        )
    }
    
    
    public init(
        discoveringBy discovery: any DiscoveryModelProtocol<ID, S, M, Failure>,
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
            if await connection.state.isConnected {
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
    
    
    private func shouldDiscovery(_ state: ConnectableDiscoveryModelState<ID, S, M, Failure>) -> Bool {
        let result = discoveryRequested && !state.discovery.isDiscovering && state.connection.isConnected
        if result {
            discoveryRequested = false
        }
        return result
    }
}
