import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothStub
import Models



public actor StubServiceModel: ServiceModelProtocol {
    nonisolated public let id: CBUUID
    
    public var state: State {
        get async { await stateDidChangeSubject.value }
    }
    nonisolated public let initialState: State
    
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    public let stateDidChangeSubject: ConcurrentValueSubject<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        self.initialState = state
        
        let stateDidChangeSubject = ConcurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        
        self.id = uuid
    }
    
    
    public func discover() {}
    public func connect() {}
    public func disconnect() {}
}


extension ServiceModelState {
    public static func makeStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil,
        discovery: DiscoveryModelState<CBUUID, CharacteristicModelState, AnyCharacteristicModel, ServiceModelFailure> = .discoveryFailed(.init(description: "TEST"), nil),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            discovery: discovery,
            connection: connection
        )
    }
    
    
    public static func makeSuccessfulStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = "Example",
        discovery: DiscoveryModelState<CBUUID, CharacteristicModelState, AnyCharacteristicModel, ServiceModelFailure> = .discovered(StateMachineArray([
            StubCharacteristicModel().eraseToAny(),
            StubCharacteristicModel().eraseToAny(),
        ])),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            discovery: discovery,
            connection: connection
        )
    }
}


extension ConnectableDiscoveryModelState<CBUUID, CharacteristicModelState, AnyCharacteristicModel, ServiceModelFailure> {
    public static func makeStub(
        discovery: DiscoveryModelState<CBUUID, CharacteristicModelState, AnyCharacteristicModel, ServiceModelFailure> = .discoveryFailed(.init(description: "TEST"), nil),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(discovery: discovery, connection: connection)
    }
    
    
    public static func makeSuccessfulStub(
        discovery: DiscoveryModelState<CBUUID, CharacteristicModelState, AnyCharacteristicModel, ServiceModelFailure> = .discovered(StateMachineArray([
            StubCharacteristicModel().eraseToAny(),
            StubCharacteristicModel().eraseToAny(),
        ])),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(discovery: discovery, connection: connection)
    }
}
