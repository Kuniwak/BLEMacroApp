import Foundation
import Combine
import CoreBluetooth
import CoreBluetoothStub
import Catalogs
import Models


public actor StubPeripheralModel: PeripheralModelProtocol {
    nonisolated public var state: PeripheralModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    nonisolated public let stateDidUpdate: AnyPublisher<PeripheralModelState, Never>
    nonisolated public let stateDidUpdateSubject: CurrentValueSubject<PeripheralModelState, Never>
    
    
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
        name: Result<String?, PeripheralModelFailure> = .failure(.init(description: "TEST")),
        rssi: Result<NSNumber, PeripheralModelFailure> = .failure(.init(description: "TEST")),
        manufacturerData: ManufacturerData? = nil,
        connectionState: ConnectionState = .connectionFailed(.init(description: "TEST"))
    ) -> Self {
        .init(
            uuid: StubUUID.zero,
            name: name,
            rssi: rssi,
            manufacturerData: manufacturerData,
            connectionState: connectionState
        )
    }
    
    
    public static func makeSuccessfulStub(
        name: Result<String?, PeripheralModelFailure> = .success("Example Device"),
        rssi: Result<NSNumber, PeripheralModelFailure> = .success(NSNumber(value: -50)),
        manufacturerData: ManufacturerData? = .knownName("Example Inc.", Data()),
        connectionState: ConnectionState = .makeSuccessfulStub()
    ) -> Self {
        .init(
            uuid: StubUUID.zero,
            name: name,
            rssi: rssi,
            manufacturerData: manufacturerData,
            connectionState: connectionState
        )
    }
}


extension ConnectionState {
    public static func makeStub() -> Self {
        .connectionFailed(.init(description: "TEST"))
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .connected
    }
}
