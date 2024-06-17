import Combine
import CoreBluetooth


public struct AttributeDiscoveryModelState<Attribute, Failure: Error> {
    public let discovery: DiscoveryModelState<Attribute, Failure>
    public let peripheral: PeripheralModelState
}


public actor AttributeDiscoveryModel<Attribute, Failure: Error>: Identifiable, ObservableObject {
    private let discovery: any DiscoveryModelProtocol<Attribute, Failure>
    private let peripheral: any PeripheralModelProtocol
    private var discoveryRequested = false
    
    
    nonisolated public let id: CBUUID
    nonisolated public let stateDidChange: AnyPublisher<AttributeDiscoveryModelState<Attribute, Failure>, Never>
    nonisolated public let objectWillChange: AnyPublisher<Void, Never>
    public var cancellables = Set<AnyCancellable>()
    
    
    public init(
        identifiedBy uuid: CBUUID,
        discoveringBy discovery: any DiscoveryModelProtocol<Attribute, Failure>,
        connectingBy peripheral: any PeripheralModelProtocol
    ) {
        self.id = uuid
        self.discovery = discovery
        self.peripheral = peripheral
        
        let stateDidChange = discovery.stateDidUpdate
            .combineLatest(peripheral.stateDidUpdate)
            .map { discoveryState, peripheralState in
                AttributeDiscoveryModelState(
                    discovery: discoveryState,
                    peripheral: peripheralState
                )
            }
        
        self.stateDidChange = stateDidChange.eraseToAnyPublisher()
        self.objectWillChange = stateDidChange.map { _ in () }.eraseToAnyPublisher()
        
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
        Task { await discovery.discover() }
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
