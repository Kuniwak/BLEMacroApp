import Foundation
import Combine
import CoreBluetooth
import CoreBluetoothStub
import Models


public class StubPeripheralModel: PeripheralModelProtocol {
    public let uuid: UUID
    public var state: PeripheralModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    public let stateDidUpdate: AnyPublisher<PeripheralModelState, Never>
    public let stateDidUpdateSubject: CurrentValueSubject<PeripheralModelState, Never>
    
    
    public init(state: PeripheralModelState = .makeStub(), identifiedBy uuid: UUID = StubUUID.zero) {
        let stateDidUpdateSubject = CurrentValueSubject<PeripheralModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        self.uuid = uuid
    }
    
    
    public func connect() {
    }
    
    
    public func cancelConnection() {
    }
    
    
    public func discoverServices() {
    }
}


extension PeripheralModelState {
    public static func makeStub(
        discoveryState: ServiceDiscoveryState = .discoverFailed(.init(description: "TEST")),
        rssi: Result<NSNumber, PeripheralModelFailure> = .failure(.init(description: "TEST")),
        name: Result<String?, PeripheralModelFailure> = .failure(.init(description: "TEST")),
        isConnectable: Bool = false,
        manufacturerName: Result<String?, PeripheralModelFailure> = .failure(.init(description: "TEST")),
        services: Result<[any ServiceModelProtocol], PeripheralModelFailure> = .failure(.init(description: "TEST"))
    ) -> Self {
        .init(
            discoveryState: discoveryState,
            rssi: rssi,
            name: name,
            isConnectable: isConnectable,
            manufacturerName: manufacturerName
        )
    }
    
    
    public static func makeSuccessfulStub(
        discoveryState: ServiceDiscoveryState = .makeSuccessfulStub(),
        rssi: Result<NSNumber, PeripheralModelFailure> = .success(NSNumber(value: -50)),
        name: Result<String?, PeripheralModelFailure> = .success("Example Device"),
        isConnectable: Bool = true,
        manufacturerName: Result<String?, PeripheralModelFailure> = .success("Example Ltd."),
        services: Result<[any ServiceModelProtocol], PeripheralModelFailure> = .success([])
    ) -> Self {
        .init(
            discoveryState: discoveryState,
            rssi: rssi,
            name: name,
            isConnectable: isConnectable,
            manufacturerName: manufacturerName
        )
    }
}


extension ServiceDiscoveryState {
    public static func makeStub(
        discoveryState: CharacteristicDiscoveryState = .discoverFailed(.init(description: "TEST")),
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = nil
    ) -> Self {
        .discoverFailed(.init(description: "TEST"))
    }
    
    
    public static func makeSuccessfulStub(
        discoveryState: CharacteristicDiscoveryState = .discovered(nil),
        uuid: CBUUID = CBUUID(nsuuid: StubUUID.zero),
        name: String? = "Example"
    ) -> Self {
        .disconnected(nil)
    }
}
