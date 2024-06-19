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


public typealias DescriptorDiscoveryModelState = DiscoveryModelState<CBUUID, DescriptorModelState, AnyDescriptorModel, CharacteristicModelFailure>
public typealias DescriptorsModel = StateMachineArray<CBUUID, DescriptorModelState, AnyDescriptorModel>


public struct CharacteristicModelState {
    public let uuid: CBUUID
    public let name: String?
    public let connection: ConnectionModelState
    public let discovery: DescriptorDiscoveryModelState
    
    
    public init(
        uuid: CBUUID,
        name: String?,
        connection: ConnectionModelState,
        discovery: DescriptorDiscoveryModelState
    ) {
        self.uuid = uuid
        self.name = name
        self.connection = connection
        self.discovery = discovery
    }
}


extension CharacteristicModelState: CustomStringConvertible {
    public var description: String {
        "CharacteristicModelState(uuid: \(uuid.uuidString), name: \(name ?? "(no name)"), connection: \(connection.description), discovery: \(discovery.description)"
    }
}


public protocol CharacteristicModelProtocol: StateMachine<CharacteristicModelState>, Identifiable<CBUUID> {
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
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    
    
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
    private let model: any ConnectableDiscoveryModelProtocol<CBUUID, DescriptorModelState, AnyDescriptorModel, CharacteristicModelFailure>
    nonisolated public let id: CBUUID
    
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    nonisolated public let initialState: State
    
    public init(
        characteristic: any CharacteristicProtocol,
        onPeripheral peripheral: any PeripheralProtocol,
        connectingBy connectionModel: any ConnectionModelProtocol
    ) {
        let discoveryModel = DiscoveryModel<CBUUID, DescriptorModelState, AnyDescriptorModel, CharacteristicModelFailure>(
            discoveringBy: descriptorDiscoveryStrategy(
                forCharacteristic: characteristic,
                onPeripheral: peripheral
            )
        )
        
        let name = CharacteristicCatalog.from(cbuuid: characteristic.uuid)?.name
        
        let initialState: State = .init(
            uuid: characteristic.uuid,
            name: name,
            connection: connectionModel.initialState,
            discovery: discoveryModel.initialState
        )
        self.initialState = initialState
        
        self.id = characteristic.uuid
        let model = ConnectableDiscoveryModel(
            discoveringBy: discoveryModel,
            connectingBy: connectionModel
        )
        self.model = model
        
        self.stateDidChange = model.stateDidChange
            .map { state in
                CharacteristicModelState(
                    uuid: characteristic.uuid,
                    name: name,
                    connection: state.connection,
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
    forCharacteristic characteristic: any CharacteristicProtocol,
    onPeripheral peripheral: any PeripheralProtocol
) -> () async -> Result<[AnyDescriptorModel], CharacteristicModelFailure> {
    return {
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
