import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothStub
import Models



public actor StubServiceModel: ServiceModelProtocol {
    nonisolated public let id: CBUUID
    
    public var state: State {
        get async { await stateDidUpdateSubject.value }
    }
    nonisolated public let initialState: State
    
    nonisolated public let stateDidUpdate: AnyPublisher<State, Never>
    public let stateDidUpdateSubject: ConcurrentValueSubject<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        self.initialState = state
        
        let stateDidUpdateSubject = ConcurrentValueSubject<State, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
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
        discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> = .discoveryFailed(.init(description: "TEST"), nil),
        peripheral: PeripheralModelState = .makeStub()
    ) -> Self {
        .init(uuid: uuid, name: name, discovery: discovery, peripheral: peripheral)
    }
    
    
    public static func makeSuccessfulStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = "Example",
        discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> = .discovered([
            StubCharacteristicModel().eraseToAny(),
            StubCharacteristicModel().eraseToAny(),
        ]),
        peripheral: PeripheralModelState = .makeStub()
    ) -> Self {
        .init(uuid: uuid, name: name, discovery: discovery, peripheral: peripheral)
    }
}


extension AttributeDiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> {
    public static func makeStub(
        discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> = .discoveryFailed(.init(description: "TEST"), nil),
        peripheral: PeripheralModelState = .makeStub()
    ) -> Self {
        .init(discovery: discovery, peripheral: peripheral)
    }
    
    
    public static func makeSuccessfulStub(
        discovery: DiscoveryModelState<AnyCharacteristicModel, ServiceModelFailure> = .discovered([
                StubCharacteristicModel().eraseToAny(),
                StubCharacteristicModel().eraseToAny(),
            ]),
        peripheral: PeripheralModelState = .makeStub()
    ) -> Self {
        .init(discovery: discovery, peripheral: peripheral)
    }
}
