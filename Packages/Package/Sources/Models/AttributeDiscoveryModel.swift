import Combine
import CoreBluetooth


public struct AttributeDiscoveryModelState<Attribute, Failure: Error> {
    public let discovery: DiscoveryModelState<Attribute, Failure>
    public let peripheral: PeripheralModelState
    
    
    public init(discovery: DiscoveryModelState<Attribute, Failure>, peripheral: PeripheralModelState) {
        self.discovery = discovery
        self.peripheral = peripheral
    }
}


public protocol AttributeDiscoveryModelProtocol<Attribute, Failure>: StateMachine, Identifiable<CBUUID> where State == AttributeDiscoveryModelState<Attribute, Failure> {
    associatedtype Attribute
    associatedtype Failure: Error
    
    func discover()
    func connect()
    func disconnect()
}


extension AttributeDiscoveryModelProtocol {
    nonisolated public func eraseToAny() -> AnyAttributeDiscoveryModel<Attribute, Failure> {
        AnyAttributeDiscoveryModel(self)
    }
}


public actor AnyAttributeDiscoveryModel<Attribute, Failure: Error>: AttributeDiscoveryModelProtocol {
    public typealias Attribute = Attribute
    public typealias Failure = Failure
    public typealias State = AttributeDiscoveryModelState<Attribute, Failure>
    
    private let base: any AttributeDiscoveryModelProtocol<Attribute, Failure>
    
    nonisolated public var stateDidUpdate: AnyPublisher<State, Never> { base.stateDidUpdate }
    nonisolated public var id: CBUUID { base.id }
    nonisolated public var initialState: State { base.initialState }

    
    public init(_ base: any AttributeDiscoveryModelProtocol<Attribute, Failure>) {
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


public actor AttributeDiscoveryModel<Attribute, Failure: Error>: AttributeDiscoveryModelProtocol {
    public typealias Attribute = Attribute
    public typealias Failure = Failure
    
    private let discovery: any DiscoveryModelProtocol<Attribute, Failure>
    private let peripheral: any PeripheralModelProtocol
    private var discoveryRequested = false
    
    nonisolated public let id: CBUUID
    
    nonisolated public let stateDidUpdate: AnyPublisher<State, Never>
    private var cancellables = Set<AnyCancellable>()
    
    nonisolated public var initialState: State {
        AttributeDiscoveryModelState(
            discovery: discovery.initialState,
            peripheral: peripheral.initialState
        )
    }
    
    
    public init(
        identifiedBy uuid: CBUUID,
        discoveringBy discovery: any DiscoveryModelProtocol<Attribute, Failure>,
        connectingBy peripheral: any PeripheralModelProtocol
    ) {
        self.id = uuid
        self.discovery = discovery
        self.peripheral = peripheral
        
        let stateDidUpdate = discovery.stateDidUpdate
            .combineLatest(peripheral.stateDidUpdate)
            .map { discoveryState, peripheralState in
                AttributeDiscoveryModelState(
                    discovery: discoveryState,
                    peripheral: peripheralState
                )
            }
        
        self.stateDidUpdate = stateDidUpdate.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        stateDidUpdate
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
            if await peripheral.state.connectionState.isConnected {
                await discovery.discover()
            } else {
                self.discoveryRequested = true
                await peripheral.connect()
            }
        }
    }
    
    
    public func connect() {
        Task { await peripheral.connect() }
    }
    
    
    public func disconnect() {
        Task { await peripheral.disconnect() }
    }
    
    
    private func shouldDiscovery(_ state: AttributeDiscoveryModelState<Attribute, Failure>) -> Bool {
        let result = discoveryRequested && !state.discovery.isDiscovering && state.peripheral.connectionState.isConnected
        if result {
            discoveryRequested = false
        }
        return result
    }
}
