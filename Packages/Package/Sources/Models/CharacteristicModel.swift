import Combine
import CoreBluetooth
import CoreBluetoothTestable
import CoreBluetoothTasks
import Catalogs


public struct CharacteristicModelFailure: Error, CustomStringConvertible {
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


public struct CharacteristicModelState {
    public let uuid: CBUUID
    public let name: String?
    public let peripheral: PeripheralModelState
    public let discovery: DiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure>
    
    
    public init(
        uuid: CBUUID,
        name: String?,
        peripheral: PeripheralModelState,
        discovery: DiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure>
    ) {
        self.uuid = uuid
        self.name = name
        self.peripheral = peripheral
        self.discovery = discovery
    }
}


public protocol CharacteristicModelProtocol: StateMachine, Identifiable<CBUUID> where State == CharacteristicModelState {
    func discover()
    func connect()
    func disconnect()
}


extension CharacteristicModelProtocol {
    nonisolated public func eraseToAny() -> AnyCharacteristicModel {
        AnyCharacteristicModel(self)
    }
}


public actor AnyCharacteristicModel: CharacteristicModelProtocol {
    private let base: any CharacteristicModelProtocol
    
    nonisolated public var initialState: State { base.initialState }
    nonisolated public var id: CBUUID { base.id }
    nonisolated public var stateDidUpdate: AnyPublisher<State, Never> { base.stateDidUpdate }
    
    
    public init(_ base: any CharacteristicModelProtocol) {
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


public actor CharacteristicModel: CharacteristicModelProtocol {
    private let model: any AttributeDiscoveryModelProtocol<AnyDescriptorModel, CharacteristicModelFailure>
    nonisolated public let id: CBUUID
    
    nonisolated public let stateDidUpdate: AnyPublisher<State, Never>
    nonisolated public let initialState: State
    
    public init(
        characteristic: any CharacteristicProtocol,
        onPeripheral peripheral: any PeripheralProtocol,
        controlledBy peripheralModel: any PeripheralModelProtocol
    ) {
        let discoveryModel = DiscoveryModel<AnyDescriptorModel, CharacteristicModelFailure>(
            identifiedBy: characteristic.uuid,
            discoveringBy: descriptorDiscoveryStrategy(forCharacteristic: characteristic),
            thatTakes: peripheral
        )
        
        let name = CharacteristicCatalog.from(cbuuid: characteristic.uuid)?.name
        
        let initialState: State = .init(
            uuid: characteristic.uuid,
            name: name,
            peripheral: peripheralModel.initialState,
            discovery: discoveryModel.initialState
        )
        self.initialState = initialState
        
        self.id = characteristic.uuid
        let model = AttributeDiscoveryModel(
            identifiedBy: characteristic.uuid,
            discoveringBy: discoveryModel,
            connectingBy: peripheralModel
        )
        self.model = model
        
        self.stateDidUpdate = model.stateDidUpdate
            .map { state in
                CharacteristicModelState(
                    uuid: characteristic.uuid,
                    name: name,
                    peripheral: state.peripheral,
                    discovery: state.discovery
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


private func descriptorDiscoveryStrategy(
    forCharacteristic characteristic: any CharacteristicProtocol
) -> (any PeripheralProtocol) async -> Result<[AnyDescriptorModel], CharacteristicModelFailure> {
    return { peripheral in
        await DiscoveryTask
            .discoverDescriptors(forCharacteristic: characteristic, onPeripheral: peripheral)
            .map { descriptors in
                descriptors.map { descriptor in
                    DescriptorModel(
                        startsWith: .initialState(fromDescriptorUUID: descriptor.uuid),
                        representing: descriptor,
                        onPeripheral: peripheral
                    ).eraseToAny()
                }
            }
            .mapError(CharacteristicModelFailure.init(wrapping:))
    }
}
