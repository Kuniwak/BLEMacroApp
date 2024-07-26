import Combine
import CoreBluetooth
import CoreBluetoothTestable
import BLETasks
import ModelFoundation
import Catalogs


public struct ServiceModelFailure: Error, CustomStringConvertible, Equatable {
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


public typealias CharacteristicDiscoveryModelState = DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure>


public struct ServiceModelState: Equatable {
    public let uuid: CBUUID
    public let name: String?
    public let isPrimary: Bool
    public let connection: ConnectionModelState
    public let discovery: CharacteristicDiscoveryModelState

    
    public init(
        uuid: CBUUID,
        name: String?,
        isPrimary: Bool,
        connection: ConnectionModelState,
        discovery: CharacteristicDiscoveryModelState
    ) {
        self.uuid = uuid
        self.name = name
        self.isPrimary = isPrimary
        self.connection = connection
        self.discovery = discovery
    }
    
    
    public var isFailed: Bool {
        connection.isFailed || discovery.isFailed
    }
}


extension ServiceModelState: CustomStringConvertible {
    public var description: String {
        "ServiceModelState(uuid: \(uuid.uuidString), name: \(name ?? "(no name)"), isPrimary: \(isPrimary), discovery: \(discovery.description), connection: \(connection.description))"
    }
}


extension ServiceModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ServiceModelState(uuid: \(uuid.uuidString.prefix(2))...\(uuid.uuidString.suffix(2)), name: \(name == nil ? ".some" : ".none"), isPrimary: \(isPrimary), discovery: \(discovery.debugDescription), connection: \(connection.debugDescription))"
    }
}


public protocol ServiceModelProtocol: StateMachineProtocol<ServiceModelState>, Identifiable<CBUUID>, CustomStringConvertible {
    nonisolated func discover()
    nonisolated func connect()
    nonisolated func disconnect()
}


extension ServiceModelProtocol {
    nonisolated public func eraseToAny() -> AnyServiceModel {
        AnyServiceModel(self)
    }
}


public final actor AnyServiceModel: ServiceModelProtocol {
    private let base: any ServiceModelProtocol
    
    nonisolated public var id: ID { base.id }
    nonisolated public var description: String { base.description }
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    
    
    public init(_ base: any ServiceModelProtocol) {
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


extension AnyServiceModel: Equatable {
    public static func == (lhs: AnyServiceModel, rhs: AnyServiceModel) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}


public final actor ServiceModel: ServiceModelProtocol {
    private let model: ConnectableDiscoveryModel<AnyCharacteristicModel, ServiceModelFailure>
    
    nonisolated private let name: String?
    nonisolated public var state: State {
        ServiceModelState(
            uuid: id,
            name: name,
            isPrimary: service.isPrimary,
            connection: model.state.connection,
            discovery: model.state.discovery
        )
    }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    nonisolated private let service: any ServiceProtocol
    nonisolated public var id: CBUUID { service.uuid }
    
    
    public init(
        representing service: any ServiceProtocol,
        onPeripheral peripheral: any PeripheralProtocol,
        controlledBy connectionModel: any ConnectionModelProtocol
    ) {
        self.service = service
        
        let name = ServiceCatalog.from(cbuuid: service.uuid)?.name
        self.name = name
        
        let model = ConnectableDiscoveryModel<AnyCharacteristicModel, ServiceModelFailure>(
            discoveringBy: DiscoveryModel<AnyCharacteristicModel, ServiceModelFailure>(
                discoveringBy: characteristicDiscoveryStrategy(
                    forService: service,
                    onPeripheral: peripheral,
                    connectingBy: connectionModel
                )
            ),
            connectingBy: connectionModel
        )
        self.model = model
        
        self.stateDidChange = model.stateDidChange
            .map { state in
                ServiceModelState(
                    uuid: service.uuid,
                    name: name,
                    isPrimary: service.isPrimary,
                    connection: state.connection,
                    discovery: state.discovery
                )
            }
            .eraseToAnyPublisher()
    }
    
    
    nonisolated public func discover() {
        model.discover()
    }
    
    
    nonisolated public func connect() {
        model.connect()
    }
    
    
    nonisolated public func disconnect() {
        model.disconnect()
    }
}


private func characteristicDiscoveryStrategy(
    forService Service: any ServiceProtocol,
    onPeripheral peripheral: any PeripheralProtocol,
    connectingBy connectionModel: any ConnectionModelProtocol
) -> () async -> Result<[AnyCharacteristicModel], ServiceModelFailure> {
    return {
        await PeripheralTasks(peripheral: peripheral)
            .discoverCharacteristics(forService: Service)
            .map { characteristics in
                characteristics.map { characteristic in
                    CharacteristicModel(
                        startsWith: "",
                        characteristic: characteristic,
                        onPeripheral: peripheral,
                        connectingBy: connectionModel
                    ).eraseToAny()
                }
            }
            .mapError(ServiceModelFailure.init(wrapping:))
    }
}


extension ServiceModel: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}
