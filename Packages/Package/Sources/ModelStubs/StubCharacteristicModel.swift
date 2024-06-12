import Combine
import CoreBluetooth
import CoreBluetoothStub
import Models


class StubCharacteristicModel: CharacteristicModelProtocol {
    public let uuid: CBUUID
    
    public var state: Models.CharacteristicModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    
    public let stateDidUpdateSubject: CurrentValueSubject<CharacteristicModelState, Never>
    public let stateDidUpdate: AnyPublisher<CharacteristicModelState, Never>
    
    
    public init(state: CharacteristicModelState = .makeStub(), identifiedBy uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero)) {
        let stateDidUpdateSubject = CurrentValueSubject<Models.CharacteristicModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        self.uuid = uuid
    }
    
    
    func discoverDescriptors() {
    }
    
    
    func refresh() {
    }
}


extension Models.CharacteristicModelState {
    public static func makeStub(
        discoveryState: DescriptorDiscoveryState = .discoverFailed(.init(description: "TEST")),
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil
    ) -> Self {
        .init(discoveryState: discoveryState, uuid: uuid, name: name)
    }
}
