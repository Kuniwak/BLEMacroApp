import Foundation
import Combine
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs
import ModelFoundation


public struct DescriptorModelState: Equatable {
    public let uuid: CBUUID
    public let name: String?
    public let value: DescriptorValueModelState
    public let connection: ConnectionModelState
    
    public init(
        uuid: CBUUID,
        name: String?,
        value: DescriptorValueModelState,
        connection: ConnectionModelState
    ) {
        self.uuid = uuid
        self.name = name
        self.value = value
        self.connection = connection
    }
    
    
    public static func initialState(
        descriptor: any DescriptorProtocol,
        connection: ConnectionModelState
    ) -> Self {
        return .init(
            uuid: descriptor.uuid,
            name: DescriptorCatalog.from(cbuuid: descriptor.uuid)?.name,
            value: .initialState(uuid: descriptor.uuid, value: nil),
            connection: connection
        )
    }
}


extension DescriptorModelState: CustomStringConvertible {
    public var description: String {
        "(uuid: \(uuid.uuidString), name: \(name ?? "nil"), value: \(value.description), connection: \(connection.description))"
    }
}


extension DescriptorModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        "(uuid: \(uuid.uuidString.prefix(2))...\(uuid.uuidString.suffix(2)), name: \(name == nil ? ".none" : ".some"), value: \(value.debugDescription), connection: \(connection.debugDescription))"
    }
}


public protocol DescriptorModelProtocol: StateMachineProtocol, Identifiable where State == DescriptorModelState {
    nonisolated func read()
    nonisolated func write()
    nonisolated func updateHexString(with string: String)
    nonisolated func connect()
    nonisolated func disconnect()
}


extension DescriptorModelProtocol {
    nonisolated public func eraseToAny() -> AnyDescriptorModel {
        AnyDescriptorModel(self)
    }
}


public final actor AnyDescriptorModel: DescriptorModelProtocol {
    private let base: any DescriptorModelProtocol
    
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    
    public init(_ base: any DescriptorModelProtocol) {
        self.base = base
    }
    
    nonisolated public func read() {
        base.read()
    }
    
    nonisolated public func write() {
        base.write()
    }
    
    nonisolated public func updateHexString(with string: String) {
        base.updateHexString(with: string)
    }
    
    nonisolated public func connect() {
        base.connect()
    }
    
    nonisolated public func disconnect() {
        base.disconnect()
    }
}


extension AnyDescriptorModel: Equatable {
    public static func == (lhs: AnyDescriptorModel, rhs: AnyDescriptorModel) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}


extension AnyDescriptorModel: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}


public actor DescriptorModel: DescriptorModelProtocol {
    private let value: any DescriptorStringValueModelProtocol
    private let connection: any ConnectionModelProtocol
    
    nonisolated public var state: State {
        DescriptorModelState(
            uuid: id,
            name: name,
            value: value.state,
            connection: connection.state
        )
    }
    
    nonisolated public let id: CBUUID
    nonisolated public let name: String?
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    public init(
        identifiedBy uuid: CBUUID,
        operateingBy value: any DescriptorStringValueModelProtocol,
        connectingBy connection: any ConnectionModelProtocol
    ) {
        self.id = uuid
        self.value = value
        self.connection = connection
        
        let name = DescriptorCatalog.from(cbuuid: uuid)?.name
        self.name = name
        
        let stateDidChange = Publishers
            .CombineLatest(
                value.stateDidChange,
                connection.stateDidChange
            )
            .map { value, connection in
                DescriptorModelState(
                    uuid: uuid,
                    name: name,
                    value: value,
                    connection: connection
                )
            }
        
        self.stateDidChange = stateDidChange.eraseToAnyPublisher()
    }
    
    nonisolated public func read() {
        value.read()
    }
    
    nonisolated public func write() {
        value.write()
    }
    
    nonisolated public func updateHexString(with string: String) {
        value.updateHexString(with: string)
    }
    
    nonisolated public func connect() {
        connection.connect()
    }
    
    nonisolated public func disconnect() {
        connection.disconnect()
    }
}
