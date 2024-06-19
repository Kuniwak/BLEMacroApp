import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothStub
import Models
import Catalogs


public actor StubPeripheralModel: PeripheralModelProtocol {
    nonisolated public let initialState: State
    
    nonisolated public let id: UUID
    
    public var state: State {
        get async { await stateDidChangeSubject.value }
    }
    public let stateDidChangeSubject: ConcurrentValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    
    public init(state: State = .makeStub(), identifiedBy uuid: UUID = StubUUID.zero) {
        self.initialState = state
        
        self.id = uuid
        
        let stateDidChangeSubject = ConcurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    public func readRSSI() {}
    public func discover() {}
    public func connect() {}
    public func disconnect() {}
}


extension PeripheralModelState {
    public static func makeStub(
        uuid: UUID = StubUUID.zero,
        name: Result<String?, PeripheralModelFailure> = .failure(.init(description: "TEST")),
        rssi: Result<NSNumber, PeripheralModelFailure> = .failure(.init(description: "TEST")),
        manufacturerData: ManufacturerData? = nil,
        connection: ConnectionModelState = .makeStub(),
        discovery: DiscoveryModelState<CBUUID, ServiceModelState, AnyServiceModel, PeripheralModelFailure> = .discoveryFailed(.init(description: "TEST"), nil)
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
        discovery: DiscoveryModelState<CBUUID, ServiceModelState, AnyServiceModel, PeripheralModelFailure> = .discovered(StateMachineArray([
            StubServiceModel().eraseToAny(),
            StubServiceModel().eraseToAny(),
        ]))
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
