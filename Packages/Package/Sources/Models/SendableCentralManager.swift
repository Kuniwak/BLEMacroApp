import os
import Combine
import CoreBluetooth
import CoreBluetoothTestable
import Logger


public protocol SendableCentralManagerProtocol: AnyActor {
    nonisolated var state: CBManagerState { get }
    nonisolated var didUpdateState: AnyPublisher<CBManagerState, Never> { get }
    nonisolated var didDiscoverPeripheral: AnyPublisher<(peripheral: any PeripheralProtocol, advertisementData: [String: Any], rssi: NSNumber), Never> { get }
    nonisolated var didConnectPeripheral: AnyPublisher<any PeripheralProtocol, Never> { get }
    nonisolated var didFailToConnectPeripheral: AnyPublisher<(peripheral: any PeripheralProtocol, error: (any Error)?), Never> { get }
    nonisolated var didDisconnectPeripheral: AnyPublisher<(peripheral: any PeripheralProtocol, error: (any Error)?), Never> { get }
    
    nonisolated func scanForPeripherals(withServices: [CBUUID]?)
    nonisolated func stopScan()
    nonisolated func connect(_ peripheral: any PeripheralProtocol)
    nonisolated func cancelPeripheralConnection(_ peripheral: any PeripheralProtocol)
}


public final actor SendableCentralManager: SendableCentralManagerProtocol {
    nonisolated public var state: CBManagerState { centralManager.state }
    nonisolated public let didUpdateState: AnyPublisher<CBManagerState, Never>
    nonisolated public let didDiscoverPeripheral: AnyPublisher<(peripheral: any PeripheralProtocol, advertisementData: [String: Any], rssi: NSNumber), Never>
    nonisolated public let didConnectPeripheral: AnyPublisher<any PeripheralProtocol, Never>
    nonisolated public let didFailToConnectPeripheral: AnyPublisher<(peripheral: any PeripheralProtocol, error: (any Error)?), Never>
    nonisolated public let didDisconnectPeripheral: AnyPublisher<(peripheral: any PeripheralProtocol, error: (any Error)?), Never>
    nonisolated private let centralManager: CentralManager
    
    
    public init(options: [String: Any]?, loggingBy logger: any LoggerProtocol) {
        let centralManager = CentralManager(
            options: options,
            loggingBy: logger
        )
            
        self.centralManager = centralManager
        self.didUpdateState = centralManager.didUpdateState
        self.didDiscoverPeripheral = centralManager.didDiscoverPeripheral
        self.didConnectPeripheral = centralManager.didConnectPeripheral
        self.didFailToConnectPeripheral = centralManager.didFailToConnectPeripheral
        self.didDisconnectPeripheral = centralManager.didDisconnectPeripheral
    }
    
    nonisolated public func scanForPeripherals(withServices: [CBUUID]?) {
        Task { self.centralManager.scanForPeripherals(withServices: withServices) }
    }
    
    nonisolated public func stopScan() {
        Task { self.centralManager.stopScan() }
    }
    
    nonisolated public func connect(_ peripheral: any PeripheralProtocol) {
        Task { self.centralManager.connect(peripheral) }
    }
    
    nonisolated public func cancelPeripheralConnection(_ peripheral: any PeripheralProtocol) {
        Task { self.centralManager.cancelPeripheralConnection(peripheral) }
    }
}
