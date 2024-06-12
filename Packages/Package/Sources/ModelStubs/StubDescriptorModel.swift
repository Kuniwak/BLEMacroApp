import Combine
import CoreBluetooth
import CoreBluetoothStub
import Models



public class StubDescriptorModel: DescriptorModelProtocol {
    public let uuid: CBUUID
    
    public var state: DescriptorModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    
    public let stateDidUpdateSubject: CurrentValueSubject<DescriptorModelState, Never>
    public let stateDidUpdate: AnyPublisher<DescriptorModelState, Never>
    
    
    public init(state: DescriptorModelState = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        let stateDidUpdateSubject = CurrentValueSubject<DescriptorModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        self.uuid = uuid
    }
    
    
    public func refresh() {
    }
}


extension DescriptorModelState {
    public static func makeStub(
        value: Result<Any?, DescriptorModelFailure> = .failure(.init(description: "TEST")),
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil
    ) -> Self {
        .init(value: value, uuid: uuid, name: name)
    }
}
