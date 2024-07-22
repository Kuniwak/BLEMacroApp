import CoreBluetooth
import CoreBluetoothStub
import Combine
import ModelFoundation
import Models


public final actor StubDescriptorModel: DescriptorModelProtocol {
    nonisolated public var state: DescriptorModelState {
        stateDidChangeSubject.value
    }
    nonisolated public var stateDidChange: AnyPublisher<Models.DescriptorModelState, Never> {
        stateDidChangeSubject.eraseToAnyPublisher()
    }
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        let stateDidChangeSubject = CurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
    }
    
    
    nonisolated public func read() {}
    nonisolated public func write() {}
    nonisolated public func updateHexString(with string: String) {}
    nonisolated public func connect() {}
    nonisolated public func disconnect() {}
}


extension StubDescriptorModel: CustomStringConvertible {
    nonisolated public var description: String {
        state.description
    }
}


extension DescriptorModelState {
    public static func makeStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil,
        value: DescriptorValueModelState = .makeStub(),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            value: value,
            connection: connection
        )
    }
    
    
    public static func makeSuccessfulStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = "Example",
        value: DescriptorValueModelState = .makeSuccessfulStub(),
        connection: ConnectionModelState = .makeSuccessfulStub()
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            value: value,
            connection: connection
        )
    }
}
