import Combine
import CoreBluetooth
import CoreBluetoothStub
import ModelFoundation
import Models



public final actor StubServiceModel: ServiceModelProtocol {
    nonisolated public let id: CBUUID
    
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        let stateDidChangeSubject = CurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        
        self.id = uuid
    }
    
    
    nonisolated public func discover() {}
    nonisolated public func connect() {}
    nonisolated public func disconnect() {}
}


extension StubServiceModel: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}


extension ServiceModelState {
    public static func makeStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil,
        discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> = .discoveryFailed(.init(description: "TEST"), nil),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            connection: connection,
            discovery: discovery
        )
    }
    
    
    public static func makeSuccessfulStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = "Example",
        discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> = .discovered([
            StubCharacteristicModel().eraseToAny(),
            StubCharacteristicModel().eraseToAny(),
        ]),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            connection: connection,
            discovery: discovery
        )
    }
}


extension ConnectableDiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> {
    public static func makeStub(
        discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> = .discoveryFailed(.init(description: "TEST"), nil),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(discovery: discovery, connection: connection)
    }
    
    
    public static func makeSuccessfulStub(
        discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> = .discovered([
            StubCharacteristicModel().eraseToAny(),
            StubCharacteristicModel().eraseToAny(),
        ]),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(discovery: discovery, connection: connection)
    }
}
