import Combine
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs


public struct ServiceModelFailure: Error {
    public let description: String
    
    
    public init(description: String) {
        self.description = description
    }
    
    
    public init(wrapping error: any Error) {
        self.description = "\(error)"
    }
    
    
    public init(wrapping error: (any Error)?) {
        if let error = error {
            self.description = "\(error)"
        } else {
            self.description = "nil"
        }
    }
}


public struct ServiceModelState {
    public var uuid: CBUUID
    public var name: String?
    public var discoveryState: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure>
    public var peripheralState: PeripheralModelState
    public var discoveryRequested: Bool
    
    
    public init(
        uuid: CBUUID,
        name: String?,
        discoveryState: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure>,
        peripheralState: PeripheralModelState,
        discoveryRequested: Bool
    ) {
        self.uuid = uuid
        self.name = name
        self.discoveryState = discoveryState
        self.peripheralState = peripheralState
        self.discoveryRequested = discoveryRequested
    }

    
    
    public static func initialState(
        uuid: CBUUID,
        name: String?,
        discoveryState: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure>,
        peripheralState: PeripheralModelState
    ) -> Self {
        ServiceModelState(
            uuid: uuid,
            name: name,
            discoveryState: discoveryState,
            peripheralState: peripheralState,
            discoveryRequested: false
        )
    }
}


extension ServiceModelState: CustomStringConvertible {
    public var description: String {
        return "ServiceModelState(uuid: \(uuid.uuidString), name: \(name ?? "nil"), discoveryState: \(discoveryState.description), peripheralState: \(peripheralState.description), discoveryRequested: \(discoveryRequested))"
    }
}


extension ServiceModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "ServiceModelState(uuid: \(uuid.uuidString), name: \(name ?? "nil"), discoveryState: \(discoveryState.debugDescription), peripheralState: \(peripheralState.debugDescription), discoveryRequested: \(discoveryRequested))"
    }
}


public protocol ServiceModelProtocol: Actor, Identifiable<CBUUID>, CustomStringConvertible, CustomDebugStringConvertible, ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    nonisolated var state: ServiceModelState { get }
    nonisolated var stateDidUpdate: AnyPublisher<ServiceModelState, Never> { get }
    func discoverCharacteristics()
    func connect()
    func disconnect()
}


extension ServiceModelProtocol {
    public func eraseToAny() -> AnyServiceModel {
        AnyServiceModel(self)
    }
}


public actor AnyServiceModel: ServiceModelProtocol {
    private let base: any ServiceModelProtocol
    
    nonisolated public var state: ServiceModelState { base.state }
    nonisolated public var stateDidUpdate: AnyPublisher<ServiceModelState, Never> { base.stateDidUpdate }
    nonisolated public var objectWillChange: ObservableObjectPublisher { base.objectWillChange }
    nonisolated public var id: CBUUID { base.id }
    nonisolated public var description: String { base.description }
    nonisolated public var debugDescription: String { base.debugDescription }
    
    
    public init(_ base: any ServiceModelProtocol) {
        self.base = base
    }
    
    
    public func discoverCharacteristics() {
        Task { await base.discoverCharacteristics() }
    }
    
    
    public func connect() {
        Task { await base.connect() }
    }
    
    
    public func disconnect() {
        Task { await base.disconnect() }
    }
}


public actor ServiceModel: ServiceModelProtocol {
    private let peripheral: any PeripheralProtocol
    private let peripheralModel: any PeripheralModelProtocol
    private let service: any ServiceProtocol
    
    private let stateDidUpdateSubject: CurrentValueSubject<ServiceModelState, Never>
    public let stateDidUpdate: AnyPublisher<ServiceModelState, Never>
    
    
    public var state: ServiceModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            objectWillChange.send()
            stateDidUpdateSubject.value = newValue
        }
    }
    
    public let objectWillChange = ObservableObjectPublisher()
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(
        startsWith initialState: ServiceModelState,
        connectingBy peripheralModel: any PeripheralModelProtocol,
        discoveringServicesBy peripheral: any PeripheralProtocol,
        forService service: any ServiceProtocol
    ) {
        self.peripheral = peripheral
        self.peripheralModel = peripheralModel
        self.service = service
        
        let stateDidUpdateSubject = CurrentValueSubject<ServiceModelState, Never>(initialState)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
        self.peripheral.didDiscoverCharacteristicsForService
            .combineLatest(peripheralModel.stateDidUpdate)
            .sink { [weak self] pair in
                guard let self else { return }
                let (resp, peripheralModelState) = pair
                guard resp.service.uuid == self.service.uuid else { return }
                
                switch (self.state.discoveryState, peripheralModelState.discoveryState) {
                case (.discovering(let characteristics), .connected), (.discovering(let characteristics), .discovered), (.discovering(let characteristics), .discoveryFailed):
                    if self.state.shouldDiscover {
                        if let characteristics {
                            self.state.discoveryState = .discovered(characteristics)
                        } else {
                            self.state.discoveryState = .notDiscoveredYet
                        }
                        self.discoverCharacteristics()
                    }
                }
                
            }
            .store(in: &cancellables)
    }
    
    
    public func discoverCharacteristics() {
        if self.peripheralModel.state.discoveryState.isConnected {
            switch state.discoveryState {
            case .notDiscoveredYet, .discovered, .discoverFailed:
                state.discoveryState = .discovering(state.discoveryState.characteristics)
                peripheral.discoverCharacteristics(nil, for: service)
            case .discovering:
                break
            }
        } else if self.peripheralModel.state.discoveryState.canConnect {
            peripheralModel.connect()
            state.discoveryState = .discovering(state.discoveryState.characteristics)
            state.shouldDiscover = true
        }
    }
    
    
    public func connect() {
        peripheralModel.connect()
    }
    
    
    public func disconnect() {
        peripheralModel.disconnect()
    }
}


extension ServiceModel: Identifiable {
    public var id: Data { state.uuid.data }
}
