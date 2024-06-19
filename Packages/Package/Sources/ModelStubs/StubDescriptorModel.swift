import Combine
import CoreBluetooth
import CoreBluetoothStub
import Models



public actor StubDescriptorModel: DescriptorModelProtocol {
    nonisolated public var state: DescriptorModelState { stateDidChangeSubject.value }
    
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<DescriptorModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<DescriptorModelState, Never>
    
    nonisolated public let id: CBUUID
    nonisolated public let initialState: DescriptorModelState

    
    public init(state: DescriptorModelState = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        self.initialState = state
        self.id = uuid
        
        let stateDidChangeSubject = CurrentValueSubject<DescriptorModelState, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    public func read() {}
    public func write(value: Data) {}
}


extension StubDescriptorModel: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}


extension DescriptorModelState {
    public static func makeStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil,
        value: Result<Any?, DescriptorModelFailure> = .failure(.init(description: "TEST"))
    ) -> Self {
        .init(uuid: uuid, name: name, value: value)
    }
}
