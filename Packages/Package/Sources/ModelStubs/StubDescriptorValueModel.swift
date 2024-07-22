import Combine
import CoreBluetooth
import CoreBluetoothStub
import Models



public final actor StubDescriptorValueModel: DescriptorValueModelProtocol {
    nonisolated public var state: DescriptorValueModelState { stateDidChangeSubject.value }
    
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<DescriptorValueModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<DescriptorValueModelState, Never>
    
    nonisolated public let id: CBUUID

    
    public init(state: DescriptorValueModelState = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        self.id = uuid
        
        let stateDidChangeSubject = CurrentValueSubject<DescriptorValueModelState, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func read() {}
    nonisolated public func write(value: Data) {}
}


extension StubDescriptorValueModel: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}


extension DescriptorValueModelState {
    public static func makeStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil,
        value: DescriptorValue? = nil,
        error: DescriptorValueModelFailure? = .init(description: "TEST"),
        canWrite: Bool = false
    ) -> Self {
        .init(value: value, error: error, canWrite: canWrite)
    }
    
    
    public static func makeSuccessfulStub(
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil,
        value: DescriptorValue? = nil,
        canWrite: Bool = true
    ) -> Self {
        .init(value: value, error: nil, canWrite: canWrite)
    }
}
