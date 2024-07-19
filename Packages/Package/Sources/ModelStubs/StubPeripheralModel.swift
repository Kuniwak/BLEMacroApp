import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothStub
import Models
import ModelFoundation
import Catalogs


public final actor StubPeripheralModel: PeripheralModelProtocol {
    nonisolated public let id: UUID
    
    nonisolated public let connection: any ConnectionModelProtocol
    nonisolated public var state: State { stateDidChangeSubject.projected }
    nonisolated public let stateDidChangeSubject: ProjectedValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: UUID = StubUUID.zero, connection: any ConnectionModelProtocol = StubConnectionModel()) {
        self.id = uuid
        
        self.connection = connection
        let stateDidChangeSubject = ProjectedValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func readRSSI() {}
    nonisolated public func discover() {}
    nonisolated public func connect() {}
    nonisolated public func disconnect() {}
}


extension PeripheralModelState {
    public static func makeStub(
        uuid: UUID = StubUUID.zero,
        name: Result<String?, PeripheralModelFailure> = .failure(.init(description: "TEST")),
        rssi: Result<NSNumber, PeripheralModelFailure> = .failure(.init(description: "TEST")),
        manufacturerData: ManufacturerData? = nil,
        connection: ConnectionModelState = .makeStub(),
        discovery: DiscoveryModelState<AnyServiceModel, PeripheralModelFailure> = .discoveryFailed(.init(description: "TEST"), nil)
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            rssi: rssi,
            manufacturerData: manufacturerData,
            connection: connection,
            discovery: discovery
        )
    }
    
    
    public static func makeSuccessfulStub(
        uuid: UUID = StubUUID.zero,
        name: Result<String?, PeripheralModelFailure> = .success("Example"),
        rssi: Result<NSNumber, PeripheralModelFailure> = .success(NSNumber(value: -50)),
        manufacturerData: ManufacturerData? = nil,
        connection: ConnectionModelState = .makeSuccessfulStub(),
        discovery: DiscoveryModelState<AnyServiceModel, PeripheralModelFailure> = .discovered([
            StubServiceModel().eraseToAny(),
            StubServiceModel().eraseToAny(),
        ])
    ) -> Self {
        .init(
            uuid: uuid,
            name: name,
            rssi: rssi,
            manufacturerData: manufacturerData,
            connection: connection,
            discovery: discovery
        )
    }
}
