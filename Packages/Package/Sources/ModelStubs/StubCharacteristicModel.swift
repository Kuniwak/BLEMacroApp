import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothStub
import Models


public actor StubCharacteristicModel: CharacteristicModelProtocol {
    nonisolated public let initialState: State
    
    nonisolated public let id: CBUUID
    
    public let stateDidChangeSubject: ConcurrentValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        self.initialState = state
        
        self.id = uuid
        
        let stateDidChangeSubject = ConcurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    public func discover() {}
    public func connect() {}
    public func disconnect() {}
}


extension CharacteristicModelState {
    public static func makeStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil,
        connection: ConnectionModelState = .makeStub(),
        discovery: DiscoveryModelState<CBUUID, DescriptorModelState, AnyDescriptorModel, CharacteristicModelFailure> = .discoveryFailed(.init(description: "TEST"), nil)
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
        connection: ConnectionModelState = .makeStub(),
        discovery: DiscoveryModelState<CBUUID, DescriptorModelState, AnyDescriptorModel, CharacteristicModelFailure> = .discovered(StateMachineArray([
            StubDescriptorModel().eraseToAny(),
            StubDescriptorModel().eraseToAny(),
        ]))
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            connection: connection,
            discovery: discovery
        )
    }
}
