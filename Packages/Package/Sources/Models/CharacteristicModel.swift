import Combine
import CoreBluetooth
import CoreBluetoothTestable
import CoreBluetoothTasks
import ModelFoundation
import Catalogs


public struct CharacteristicModelFailure: Error, CustomStringConvertible, Equatable {
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


public typealias DescriptorDiscoveryModelState = DiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure>


public struct CharacteristicModelState: Equatable {
    public let uuid: CBUUID
    public let name: String?
    public let value: CharacteristicStringValueState
    public let connection: ConnectionModelState
    public let discovery: DescriptorDiscoveryModelState
    
    
    public init(
        uuid: CBUUID,
        name: String?,
        value: CharacteristicStringValueState,
        connection: ConnectionModelState,
        discovery: DescriptorDiscoveryModelState
    ) {
        self.uuid = uuid
        self.name = name
        self.value = value
        self.connection = connection
        self.discovery = discovery
    }
}


extension CharacteristicModelState: CustomStringConvertible {
    public var description: String {
        "(uuid: \(uuid.uuidString), name: \(name ?? "(no name)"), connection: \(connection.description), discovery: \(discovery.description)"
    }
}


extension CharacteristicModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        "(uuid: \(uuid.uuidString.prefix(2))...\(uuid.uuidString.suffix(2)), name: \(name == nil ? ".some" : ".none"), connection: \(connection.debugDescription), discovery: \(discovery.debugDescription)"
    }
}


public protocol CharacteristicModelProtocol: StateMachineProtocol<CharacteristicModelState>, Identifiable<CBUUID>, CustomStringConvertible {
    nonisolated func discover()
    nonisolated func connect()
    nonisolated func disconnect()
    nonisolated func read()
    nonisolated func write(type: CBCharacteristicWriteType)
    nonisolated func update(byString string: String)
    nonisolated func setNotify(_ enabled: Bool)
}


extension CharacteristicModelProtocol {
    nonisolated public func eraseToAny() -> AnyCharacteristicModel {
        AnyCharacteristicModel(self)
    }
}


public final actor AnyCharacteristicModel: CharacteristicModelProtocol {
    private let base: any CharacteristicModelProtocol
    
    nonisolated public var state: State { base.state }
    nonisolated public var id: CBUUID { base.id }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    nonisolated public var description: String { base.description }
    
    
    public init(_ base: any CharacteristicModelProtocol) {
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
    
    
    nonisolated public func read() {
        base.read()
    }
    
    
    nonisolated public func write(type: CBCharacteristicWriteType) {
        base.write(type: type)
    }
    
    
    nonisolated public func update(byString string: String) {
        base.update(byString: string)
    }
    
    
    nonisolated public func setNotify(_ enabled: Bool) {
        base.setNotify(enabled)
    }
}


extension AnyCharacteristicModel: Equatable {
    public static func == (lhs: AnyCharacteristicModel, rhs: AnyCharacteristicModel) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}


public final actor CharacteristicModel: CharacteristicModelProtocol {
    nonisolated private let connectableDiscoveryModel: any ConnectableDiscoveryModelProtocol<AnyDescriptorModel, CharacteristicModelFailure>
    nonisolated private let valueModel: any CharacteristicStringValueModelProtocol
    nonisolated public let id: CBUUID
    
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    nonisolated public var state: State {
        CharacteristicModelState(
            uuid: id,
            name: CharacteristicCatalog.from(cbuuid: id)?.name,
            value: valueModel.state,
            connection: connectableDiscoveryModel.state.connection,
            discovery: connectableDiscoveryModel.state.discovery
        )
    }
    nonisolated public var description: String { state.description }
    
    public init(
        startsWith initialState: String,
        characteristic: any CharacteristicProtocol,
        onPeripheral peripheral: any PeripheralProtocol,
        connectingBy connectionModel: any ConnectionModelProtocol
    ) {
        self.id = characteristic.uuid
        
        let discoveryModel = DiscoveryModel<AnyDescriptorModel, CharacteristicModelFailure>(
            discoveringBy: descriptorDiscoveryStrategy(
                forCharacteristic: characteristic,
                onPeripheral: peripheral
            )
        )
        
        let connectableDiscoveryModel = ConnectableDiscoveryModel(
            discoveringBy: discoveryModel,
            connectingBy: connectionModel
        )
        self.connectableDiscoveryModel = connectableDiscoveryModel
        
        let valueModel = CharacteristicStringValueModel(
            startsWith: initialState,
            operatingOn: peripheral,
            representing: characteristic
        )
        self.valueModel = valueModel

        self.stateDidChange = Publishers
            .CombineLatest(
                connectableDiscoveryModel.stateDidChange,
                valueModel.stateDidChange
            )
            .map { (connectableDiscoveryState, valueState) in
                CharacteristicModelState(
                    uuid: characteristic.uuid,
                    name: CharacteristicCatalog.from(cbuuid: characteristic.uuid)?.name,
                    value: valueState,
                    connection: connectableDiscoveryState.connection,
                    discovery: connectableDiscoveryState.discovery
                )
            }
            .eraseToAnyPublisher()
    }
    
    nonisolated public func discover() {
        connectableDiscoveryModel.discover()
    }
    
    nonisolated public func connect() {
        connectableDiscoveryModel.connect()
    }
    
    nonisolated public func disconnect() {
        connectableDiscoveryModel.disconnect()
    }
    
    nonisolated public func read() {
        valueModel.read()
    }
    
    nonisolated public func write(type: CBCharacteristicWriteType) {
        valueModel.write(type: type)
    }
    
    nonisolated public func update(byString string: String) {
        valueModel.update(byString: string)
    }
    
    nonisolated public func setNotify(_ enabled: Bool) {
        valueModel.setNotify(enabled)
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
