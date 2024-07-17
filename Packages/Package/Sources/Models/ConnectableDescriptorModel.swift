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
    
    func read()
    func write(value: Data)
    func connect()
    func disconnect()
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
    
    public func read() {
        Task { await base.read() }
    }
    
    public func write(value: Data) {
        Task { await base.write(value: value) }
    }
    
    public func connect() {
        Task { await base.connect() }
    }
    
    public func disconnect() {
        Task { await base.disconnect() }
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
    
    public func read() {
        Task { await descriptor.read() }
    }
    
    public func write(value: Data) {
        Task { await descriptor.write(value: value) }
    }
    
    public func connect() {
        Task { await connection.connect() }
    }
    
    public func disconnect() {
        Task { await connection.disconnect() }
    }
}
