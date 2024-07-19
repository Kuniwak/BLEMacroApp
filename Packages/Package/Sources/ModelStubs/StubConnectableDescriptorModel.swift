import CoreBluetooth
import CoreBluetoothStub
import Combine
import ModelFoundation
import Models


public final actor StubConnectableDescriptorModel: ConnectableDescriptorModelProtocol {
    nonisolated public var state: Models.ConnectableDescriptorModelState {
        stateDidChangeSubject.value
    }
    nonisolated public var stateDidChange: AnyPublisher<Models.ConnectableDescriptorModelState, Never> {
        stateDidChangeSubject.eraseToAnyPublisher()
    }
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        let stateDidChangeSubject = CurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
    }
    
    
    nonisolated public func read() {}
    nonisolated public func write(value: Data) {}
    nonisolated public func connect() {}
    nonisolated public func disconnect() {}
}


extension StubConnectableDescriptorModel: CustomStringConvertible {
    nonisolated public var description: String {
        state.description
    }
}


extension ConnectableDescriptorModelState {
    public static func makeStub(
        descriptor: DescriptorModelState = .makeStub(),
        connection: ConnectionModelState = .makeStub()
    ) -> Self {
        .init(
            descriptor: descriptor,
            connection: connection
        )
    }
    
    
    public static func makeSuccessfulStub(
        descriptor: DescriptorModelState = .makeStub(),
        connection: ConnectionModelState = .makeSuccessfulStub()
    ) -> Self {
        .init(
            descriptor: descriptor,
            connection: connection
        )
    }
}
