import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothStub
import ModelFoundation
import Models


public final actor StubCharacteristicModel: CharacteristicModelProtocol {
    nonisolated public let id: CBUUID
    
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        self.id = uuid
        
        let stateDidChangeSubject = CurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func discover() {}
    nonisolated public func connect() {}
    nonisolated public func disconnect() {}
    nonisolated public func read() {}
    nonisolated public func write(type: CBCharacteristicWriteType) {}
    nonisolated public func update(byString string: String) {}
    nonisolated public func setNotify(_ enabled: Bool) {}
}


extension StubCharacteristicModel: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}


extension CharacteristicModelState {
    public static func makeStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil,
        value: CharacteristicStringValueState = .makeStub(),
        connection: ConnectionModelState = .makeStub(),
        discovery: DiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure> = .discoveryFailed(.init(description: "TEST"), nil)
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            value: value,
            connection: connection,
            discovery: discovery
        )
    }
    
    
    public static func makeSuccessfulStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = "Example",
        value: CharacteristicStringValueState = .makeSuccessfulStub(),
        connection: ConnectionModelState = .makeStub(),
        discovery: DiscoveryModelState<AnyDescriptorModel, CharacteristicModelFailure> = .discovered([
            StubDescriptorModel().eraseToAny(),
            StubDescriptorModel().eraseToAny(),
        ])
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            value: value,
            connection: connection,
            discovery: discovery
        )
    }
}
