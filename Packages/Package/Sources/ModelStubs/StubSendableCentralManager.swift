import Combine
import CoreBluetooth
import CoreBluetoothTestable
import Models


public final actor StubSendableCentralManager: SendableCentralManagerProtocol {
    nonisolated public var state: CBManagerState { didUpdateStateSubject.value }
    
    nonisolated public let didUpdateState: AnyPublisher<CBManagerState, Never>
    nonisolated public let didUpdateStateSubject: CurrentValueSubject<CBManagerState, Never>
    
    nonisolated public let didDiscoverPeripheral: AnyPublisher<(peripheral: any PeripheralProtocol, advertisementData: [String : Any], rssi: NSNumber), Never>
    nonisolated public let didDiscoverPeripheralSubject: PassthroughSubject<(peripheral: any PeripheralProtocol, advertisementData: [String : Any], rssi: NSNumber), Never>
    
    nonisolated public let didConnectPeripheral: AnyPublisher<any PeripheralProtocol, Never>
    nonisolated public let didConnectPeripheralSubject: PassthroughSubject<any PeripheralProtocol, Never>
    
    nonisolated public let didFailToConnectPeripheral: AnyPublisher<(peripheral: any PeripheralProtocol, error: (any Error)?), Never>
    nonisolated public let didFailToConnectPeripheralSubject: PassthroughSubject<(peripheral: any PeripheralProtocol, error: (any Error)?), Never>
    
    nonisolated public let didDisconnectPeripheral: AnyPublisher<(peripheral: any PeripheralProtocol, error: (any Error)?), Never>
    nonisolated public let didDisconnectPeripheralSubject: PassthroughSubject<(peripheral: any PeripheralProtocol, error: (any Error)?), Never>
    
    
    public init(state: CBManagerState) {
        let didUpdateStateSubject = CurrentValueSubject<CBManagerState, Never>(state)
        self.didUpdateStateSubject = didUpdateStateSubject
        self.didUpdateState = didUpdateStateSubject.eraseToAnyPublisher()
        
        let didDiscoverPeripheralSubject = PassthroughSubject<(peripheral: any PeripheralProtocol, advertisementData: [String : Any], rssi: NSNumber), Never>()
        self.didDiscoverPeripheralSubject = didDiscoverPeripheralSubject
        self.didDiscoverPeripheral = didDiscoverPeripheralSubject.eraseToAnyPublisher()
        
        let didConnectPeripheralSubject = PassthroughSubject<any PeripheralProtocol, Never>()
        self.didConnectPeripheralSubject = didConnectPeripheralSubject
        self.didConnectPeripheral = didConnectPeripheralSubject.eraseToAnyPublisher()
        
        let didFailToConnectPeripheralSubject = PassthroughSubject<(peripheral: any PeripheralProtocol, error: (any Error)?), Never>()
        self.didFailToConnectPeripheralSubject = didFailToConnectPeripheralSubject
        self.didFailToConnectPeripheral = didFailToConnectPeripheralSubject.eraseToAnyPublisher()
        
        let didDisconnectPeripheralSubject = PassthroughSubject<(peripheral: any PeripheralProtocol, error: (any Error)?), Never>()
        self.didDisconnectPeripheralSubject = didDisconnectPeripheralSubject
        self.didDisconnectPeripheral = didDisconnectPeripheralSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func scanForPeripherals(withServices: [CBUUID]?) {}
    nonisolated public func stopScan() {}
    nonisolated public func connect(_ peripheral: any PeripheralProtocol) {}
    nonisolated public func cancelPeripheralConnection(_ peripheral: any PeripheralProtocol) {}
}
