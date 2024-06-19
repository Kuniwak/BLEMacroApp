import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothStub
import Models


public actor StubCharacteristicModel: CharacteristicModelProtocol {
    nonisolated public let initialState: State
    
    nonisolated public let id: CBUUID
    
    public let stateDidUpdateSubject: ConcurrentValueSubject<State, Never>
    nonisolated public let stateDidUpdate: AnyPublisher<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        self.initialState = state
        
        self.id = uuid
        
        let stateDidUpdateSubject = ConcurrentValueSubject<State, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
    }
    
    
    public func discover() {}
    public func connect() {}
    public func disconnect() {}
}


extension CharacteristicModelState {
    public static func makeStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil,
        discovery: DiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure> = .discoveryFailed(.init(description: "TEST"), nil),
        peripheral: PeripheralModelState = .makeStub()
    ) -> Self {
        .init(uuid: uuid, name: name, peripheral: peripheral, discovery: discovery)
    }
    
    
    public static func makeSuccessfulStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = "Example",
        discovery: DiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure> = .discovered([
            StubDescriptorModel().eraseToAny(),
            StubDescriptorModel().eraseToAny(),
        ]),
        peripheral: PeripheralModelState = .makeStub()
    ) -> Self {
        .init(uuid: uuid, name: name, peripheral: peripheral, discovery: discovery)
    }
}


extension AttributeDiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure> {
    public static func makeStub(
        discovery: DiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure> = .discoveryFailed(.init(description: "TEST"), nil),
        peripheral: PeripheralModelState = .makeStub()
    ) -> Self {
        .init(discovery: discovery, peripheral: peripheral)
    }
    
    
    public static func makeSuccessfulStub(
        discovery: DiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure> = .discovered([
                StubDescriptorModel().eraseToAny(),
                StubDescriptorModel().eraseToAny(),
            ]),
        peripheral: PeripheralModelState = .makeStub()
    ) -> Self {
        .init(discovery: discovery, peripheral: peripheral)
    }
}
