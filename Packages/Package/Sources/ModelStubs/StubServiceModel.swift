import Combine
import CoreBluetooth
import CoreBluetoothStub
import Models



public class StubServiceModel: ServiceModelProtocol {
    public let uuid: CBUUID
    
    public var state: ServiceModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    
    public let stateDidUpdate: AnyPublisher<ServiceModelState, Never>
    public let stateDidUpdateSubject: CurrentValueSubject<ServiceModelState, Never>
    
    
    public init(state: ServiceModelState = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        let stateDidUpdateSubject = CurrentValueSubject<ServiceModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        self.uuid = uuid
    }
    
    
    public func discoverCharacteristics() {
    }
    
    
    public func refresh() {
    }
}


extension ServiceModelState {
    public static func makeStub(
        discoveryState: CharacteristicDiscoveryState = .discoverFailed(.init(description: "TEST")),
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil
    ) -> Self {
        .init(discoveryState: discoveryState, uuid: uuid, name: name)
    }
}


extension CharacteristicDiscoveryState {
    public static func makeStub() -> Self {
        .discoverFailed(.init(description: "TEST"))
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .discovered([
            StubCharacteristicModel().eraseToAny(),
            StubCharacteristicModel().eraseToAny(),
        ])
    }
}
