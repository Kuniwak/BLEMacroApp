import Foundation
import Combine
import CoreBluetooth
import CoreBluetoothStub
import Catalogs
import Models


public class StubPeripheralModel: PeripheralModelProtocol {
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
    
    
    public init(state: PeripheralModelState = .makeStub()) {
        let stateDidUpdateSubject = CurrentValueSubject<PeripheralModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
    }
    
    
    public func connect() {
    }
    
    
    public func disconnect() {
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
        manufacturerData: ManufacturerData? = nil,
        services: Result<[any ServiceModelProtocol], PeripheralModelFailure> = .failure(.init(description: "TEST"))
    ) -> Self {
        .init(
            uuid: StubUUID.zero,
            discoveryState: discoveryState,
            rssi: rssi,
            name: name,
            isConnectable: isConnectable,
            manufacturerData: manufacturerData
        )
    }
    
    
    public static func makeSuccessfulStub(
        discoveryState: ServiceDiscoveryState = .makeSuccessfulStub(),
        rssi: Result<NSNumber, PeripheralModelFailure> = .success(NSNumber(value: -50)),
        name: Result<String?, PeripheralModelFailure> = .success("Example Device"),
        isConnectable: Bool = true,
        manufacturerData: ManufacturerData? = .knownName("Example Inc.", Data()),
        services: Result<[any ServiceModelProtocol], PeripheralModelFailure> = .success([])
    ) -> Self {
        .init(
            uuid: StubUUID.zero,
            discoveryState: discoveryState,
            rssi: rssi,
            name: name,
            isConnectable: isConnectable,
            manufacturerData: manufacturerData
        )
    }
}


extension ServiceDiscoveryState {
    public static func makeStub() -> Self {
        .discoverFailed(.init(description: "TEST"))
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .discovered([
            StubServiceModel().eraseToAny(),
            StubServiceModel().eraseToAny(),
        ])
    }
}
