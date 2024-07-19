import Foundation
import Combine
import ModelFoundation


public struct ConnectableDescriptorModelState: Equatable {
    public let descriptor: DescriptorModelState
    public let connection: ConnectionModelState
    
    public init(descriptor: DescriptorModelState, connection: ConnectionModelState) {
        self.descriptor = descriptor
        self.connection = connection
    }
}


extension ConnectableDescriptorModelState: CustomStringConvertible {
    public var description: String {
        "(descriptor: \(descriptor.description), connection: \(connection.description))"
    }
}


public protocol ConnectableDescriptorModelProtocol: StateMachineProtocol, Identifiable where State == ConnectableDescriptorModelState {
    nonisolated func read()
    nonisolated func write(value: Data)
    nonisolated func connect()
    nonisolated func disconnect()
}


extension ConnectableDescriptorModelProtocol {
    nonisolated public func eraseToAny() -> AnyConnectableDescriptorModel {
        AnyConnectableDescriptorModel(self)
    }
}


public final actor AnyConnectableDescriptorModel: ConnectableDescriptorModelProtocol {
    private let base: any ConnectableDescriptorModelProtocol
    
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    
    public init(_ base: any ConnectableDescriptorModelProtocol) {
        self.base = base
    }
    
    nonisolated public func read() {
        base.read()
    }
    
    nonisolated public func write(value: Data) {
        base.write(value: value)
    }
    
    nonisolated public func connect() {
        base.connect()
    }
    
    nonisolated public func disconnect() {
        base.disconnect()
    }
}


extension AnyConnectableDescriptorModel: Equatable {
    public static func == (lhs: AnyConnectableDescriptorModel, rhs: AnyConnectableDescriptorModel) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}


public actor ConnectableDescriptorModel: ConnectableDescriptorModelProtocol {
    private let descriptor: any DescriptorModelProtocol
    private let connection: any ConnectionModelProtocol
    
    nonisolated public var state: State {
        ConnectableDescriptorModelState(
            descriptor: descriptor.state,
            connection: connection.state
        )
    }
    
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    public init(
        operateingBy descriptor: any DescriptorModelProtocol,
        connectingBy connection: any ConnectionModelProtocol
    ) {
        self.descriptor = descriptor
        self.connection = connection
        
        let stateDidChange = Publishers
            .CombineLatest(
                descriptor.stateDidChange,
                connection.stateDidChange
            )
            .map { descriptorState, connection in
                ConnectableDescriptorModelState(
                    descriptor: descriptorState,
                    connection: connection
                )
            }
        
        self.stateDidChange = stateDidChange.eraseToAnyPublisher()
    }
    
    nonisolated public func read() {
        descriptor.read()
    }
    
    nonisolated public func write(value: Data) {
        descriptor.write(value: value)
    }
    
    nonisolated public func connect() {
        connection.connect()
    }
    
    nonisolated public func disconnect() {
        connection.disconnect()
    }
}
