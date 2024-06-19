import Combine
import CoreBluetooth
import CoreBluetoothStub
import Models



public actor StubDescriptorModel: DescriptorModelProtocol {
    public var state: DescriptorModelState {
        get async { stateDidUpdateSubject.value }
    }
    
    nonisolated public let stateDidUpdateSubject: CurrentValueSubject<DescriptorModelState, Never>
    nonisolated public let stateDidUpdate: AnyPublisher<DescriptorModelState, Never>
    
    nonisolated public let id: CBUUID
    nonisolated public let initialState: DescriptorModelState

    
    public init(state: DescriptorModelState = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        self.initialState = state
        self.id = uuid
        
        let stateDidUpdateSubject = CurrentValueSubject<DescriptorModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
    }
    
    
    public func read() {}
    public func write(value: Data) {}
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
