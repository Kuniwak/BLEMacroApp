import Combine
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs
import CoreBluetoothTasks


public struct ServiceModelFailure: Error, CustomStringConvertible {
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
    public let uuid: CBUUID
    public let name: String?
    public let discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure>
    public let peripheral: PeripheralModelState
    
    
    public init(
        uuid: CBUUID,
        name: String?,
        discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure>,
        peripheral: PeripheralModelState
    ) {
        self.uuid = uuid
        self.name = name
        self.discovery = discovery
        self.peripheral = peripheral
    }
}


public protocol ServiceModelProtocol: StateMachine, Identifiable<CBUUID> where State == ServiceModelState {
    func discover()
    func connect()
    func disconnect()
}


extension ServiceModelProtocol {
    nonisolated public func eraseToAny() -> AnyServiceModel {
        AnyServiceModel(self)
    }
}


public actor AnyServiceModel: ServiceModelProtocol {
    private let base: any ServiceModelProtocol
    
    nonisolated public var id: CBUUID { base.id }
    nonisolated public var initialState: ServiceModelState { base.initialState }
    nonisolated public var stateDidUpdate: AnyPublisher<ServiceModelState, Never> { base.stateDidUpdate }
    
    
    public init(_ base: any ServiceModelProtocol) {
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


public actor ServiceModel: ServiceModelProtocol {
    private let model: AttributeDiscoveryModel<AnyCharacteristicModel, ServiceModelFailure>
    
    nonisolated public let initialState: State
    nonisolated public let stateDidUpdate: AnyPublisher<ServiceModelState, Never>
    
    nonisolated public let id: CBUUID
    
    
    public init(
        service: any ServiceProtocol,
        onPeripheral peripheral: any PeripheralProtocol,
        controlledBy peripheralModel: any PeripheralModelProtocol
    ) {
        self.id = service.uuid
        
        let discoveryModel = DiscoveryModel<AnyCharacteristicModel, ServiceModelFailure>(
            identifiedBy: service.uuid,
            discoveringBy: characteristicDiscoveryStrategy(forService: service, onPeripheral: peripheralModel),
            thatTakes: peripheral
        )
        
        let name = ServiceCatalog.from(cbuuid: service.uuid)?.name
        
        let initialState: State = .init(
            uuid: service.uuid,
            name: name,
            discovery: discoveryModel.initialState,
            peripheral: peripheralModel.initialState
        )
        self.initialState = initialState
        
        let model = AttributeDiscoveryModel<AnyCharacteristicModel, ServiceModelFailure>(
            identifiedBy: service.uuid,
            discoveringBy: discoveryModel,
            connectingBy: peripheralModel
        )
        self.model = model
        
        self.stateDidUpdate = model.stateDidUpdate
            .map { state in
                ServiceModelState(
                    uuid: service.uuid,
                    name: name,
                    discovery: state.discovery,
                    peripheral: state.peripheral
                )
            }
            .eraseToAnyPublisher()
    }
    
    
    public func discover() {
        Task { await model.discover() }
    }
    
    
    public func connect() {
        Task { await model.connect() }
    }
    
    
    public func disconnect() {
        Task { await model.disconnect() }
    }
}


private func characteristicDiscoveryStrategy(
    forService Service: any ServiceProtocol,
    onPeripheral peripheralModel: any PeripheralModelProtocol
) -> (any PeripheralProtocol) async -> Result<[AnyCharacteristicModel], ServiceModelFailure> {
    return { peripheral in
        await DiscoveryTask
            .discoverCharacteristics(forService: Service, onPeripheral: peripheral)
            .map { characteristics in
                characteristics.map { characteristic in
                    CharacteristicModel(
                        characteristic: characteristic,
                        onPeripheral: peripheral,
                        controlledBy: peripheralModel
                    ).eraseToAny()
                }
            }
            .mapError(ServiceModelFailure.init(wrapping:))
    }
}
