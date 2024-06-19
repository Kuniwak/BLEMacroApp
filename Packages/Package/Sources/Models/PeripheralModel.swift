import Foundation
import Combine
import BLEInternal
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs
import ConcurrentCombine


public struct PeripheralModelFailure: Error, Equatable, CustomStringConvertible {
    public let description: String
    
    
    public init(description: String) {
        self.description = description
    }
    
    
    public init(wrapping error: any Error) {
        self.description = "\(error)"
    }
    
    
    public init(wrapping error: (any Error)?) {
        if let error = error {
            self.description = "\(error)"
        } else {
            self.description = "nil"
        }
    }
}


public enum ConnectionState: Equatable {
    case notConnectable
    case disconnected
    case connectionFailed(PeripheralModelFailure)
    case connecting
    case connected
    case disconnecting
    
    
    public var canConnect: Bool {
        switch self {
        case .notConnectable, .connected, .connecting, .disconnecting:
            return false
        case .disconnected, .connectionFailed:
            return true
        }
    }
    
    
    public var isConnected: Bool {
        switch self {
        case .connected:
            return true
        case .disconnected, .connecting, .disconnecting, .notConnectable, .connectionFailed:
            return false
        }
    }
}


extension ConnectionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notConnectable:
            return ".notConnectable"
        case .disconnected:
            return ".disconnected"
        case .connectionFailed(let error):
            return ".connectionFailed(\(error.description))"
        case .connecting:
            return ".connecting"
        case .connected:
            return ".connected"
        case .disconnecting:
            return ".disconnecting"
        }
    }
}


extension PeripheralModelState: Identifiable {
    public var id: UUID { uuid }
}


public struct PeripheralModelState {
    public var uuid: UUID
    public var connectionState: ConnectionState
    public var name: Result<String?, PeripheralModelFailure>
    public var rssi: Result<NSNumber, PeripheralModelFailure>
    public var manufacturerData: ManufacturerData?

    
    public init(
        uuid: UUID,
        name: Result<String?, PeripheralModelFailure>,
        rssi: Result<NSNumber, PeripheralModelFailure>,
        manufacturerData: ManufacturerData?,
        connectionState: ConnectionState
    ) {
        self.uuid = uuid
        self.name = name
        self.rssi = rssi
        self.manufacturerData = manufacturerData
        self.connectionState = connectionState
    }
    
    
    public static func initialState(
        uuid: UUID,
        name: String?,
        rssi: NSNumber,
        advertisementData: [String: Any]
    ) -> Self {
        let isConnectable: Bool
        if let flag = advertisementData[CBAdvertisementDataIsConnectable] as? Bool {
            isConnectable = flag
        } else {
            // NOTE: Assume connectable if not specified.
            isConnectable = true
        }
        
        let manufacturerData: ManufacturerData?
        if let manufacturerRawData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            manufacturerData = ManufacturerCatalog.from(data: manufacturerRawData)
        } else {
            manufacturerData = nil
        }
        
        return PeripheralModelState(
            uuid: uuid,
            name: .success(name),
            rssi: .success(rssi),
            manufacturerData: manufacturerData,
            connectionState: isConnectable
                ? .disconnected // T2
                : .notConnectable // T1
        )
    }
}


extension PeripheralModelState: CustomStringConvertible {
    public var description: String {
        let name: String
        switch self.name {
        case .success(.some(let value)):
            name = value
        case .success(.none):
            name = "nil"
        case .failure(let error):
            name = error.description
        }
        
        let rssi: String
        switch self.rssi {
        case .success(let value):
            rssi = "\(value)"
        case .failure(let error):
            rssi = error.description
        }
        
        let manufacturerData: String
        if let data = self.manufacturerData {
            manufacturerData = data.description
        } else {
            manufacturerData = "nil"
        }
        
        return "PeripheralModelState(uuid: \(uuid), name: \(name), rssi: \(rssi), manufacturerData: \(manufacturerData), connectionState: \(connectionState.description))"
    }
}


extension PeripheralModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        let name: String
        switch self.name {
        case .success(.some(let value)):
            name = value
        case .success(.none):
            name = "nil"
        case .failure(let error):
            name = error.description
        }
        
        let rssi: String
        switch self.rssi {
        case .success(let value):
            rssi = "\(value)"
        case .failure(let error):
            rssi = error.description
        }
        
        let manufacturerData: String
        if let data = self.manufacturerData {
            manufacturerData = data.debugDescription
        } else {
            manufacturerData = "nil"
        }
        
        return "PeripheralModelState(uuid: \(uuid), name: \(name), rssi: \(rssi), manufacturerData: \(manufacturerData), discoveryState: \(connectionState.description))"
    }
}


public protocol PeripheralModelProtocol: StateMachine, Identifiable where State == PeripheralModelState {
    var state: State { get async }
    
    func connect()
    func disconnect()
}


extension PeripheralModelProtocol {
    nonisolated public func eraseToAny() -> AnyPeripheralModel {
        AnyPeripheralModel(self)
    }
}


public actor AnyPeripheralModel: PeripheralModelProtocol {
    private let base: any PeripheralModelProtocol
    
    public var state: PeripheralModelState {
        get async { await base.state }
    }
    nonisolated public var stateDidUpdate: AnyPublisher<PeripheralModelState, Never> { base.stateDidUpdate }
    nonisolated public var initialState: PeripheralModelState { base.initialState }

    
    public init(_ base: any PeripheralModelProtocol) {
        self.base = base
    }
    
    
    public func connect() {
        Task { await base.connect() }
    }
    
    
    public func disconnect() {
        Task { await base.disconnect() }
    }
}


// ```marmaid
// stateDiagram-v2
//     state ".notConnectable" as notconnectable
//     state ".disconnected" as disconnected
//     state ".connectionFailed(error)" as connectionfailed
//     state ".connecting" as connecting
//     state ".connected" as connected
//
//     [*] --> notconnectable: T1 tau
//     [*] --> disconnected: T2 tau
//     disconnected --> connecting: T3 connect()
//     connecting --> connected: T4 tau
//     connecting --> connectionfailed: T5 tau
//     connectionfailed --> connecting: T6 connect()
//     connected --> disconnecting: T7 disconnect()
//     disconnecting --> disconnected: T8 tau
// ```
public actor PeripheralModel: PeripheralModelProtocol {
    private let peripheral: any PeripheralProtocol
    private let centralManager: any CentralManagerProtocol
    nonisolated public let id: UUID
    
    public var state: PeripheralModelState {
        get async { await stateDidUpdateSubject.value }
    }
    
    private let stateDidUpdateSubject: ConcurrentValueSubject<PeripheralModelState, Never>
    nonisolated public let stateDidUpdate: AnyPublisher<PeripheralModelState, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    nonisolated public let initialState: PeripheralModelState
    
    
    public init(
        startsWith initialState: PeripheralModelState,
        centralManager: any CentralManagerProtocol,
        peripheral: any PeripheralProtocol
    ) {
        self.centralManager = centralManager
        self.peripheral = peripheral
        self.id = peripheral.identifier
        
        self.initialState = initialState
        let didUpdateSubject = ConcurrentValueSubject<PeripheralModelState, Never>(initialState)
        self.stateDidUpdateSubject = didUpdateSubject
        self.stateDidUpdate = didUpdateSubject.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        centralManager.didConnectPeripheral
            .sink { [weak self] peripheral in
                guard let self else { return }
                guard peripheral.identifier == self.id else { return }
                
                Task {
                    await self.stateDidUpdateSubject.change { prev in
                        guard case .connecting = prev.connectionState else { return prev }
                        // T4
                        var new = prev
                        new.connectionState = .connected
                        return new
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        centralManager.didFailToConnectPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.peripheral.identifier == self.id else { return }
                
                Task {
                    await self.stateDidUpdateSubject.change { prev in
                        guard case .connecting = prev.connectionState else { return prev }
                        // T5
                        var new = prev
                        new.connectionState = .connectionFailed(.init(wrapping: resp.error))
                        return new
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        centralManager.didDisconnectPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.peripheral.identifier == self.id else { return }
                
                Task {
                    await self.stateDidUpdateSubject.change { prev in
                        // T8
                        var new = prev
                        new.connectionState = .disconnected
                        return new
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        peripheral.didUpdateRSSI
            .sink { [weak self] resp in
                guard let self else { return }
                
                Task {
                    await self.stateDidUpdateSubject.change { prev in
                        guard case .connected = prev.connectionState else { return prev }
                        if let rssi = resp.rssi {
                            var new = prev
                            new.rssi = .success(rssi)
                            return new
                        } else {
                            var new = prev
                            new.rssi = .failure(PeripheralModelFailure(wrapping: resp.error))
                            return new
                        }
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        peripheral.didUpdateName
            .sink { [weak self] name in
                guard let self else { return }
                
                Task {
                    await self.stateDidUpdateSubject.change { prev in
                        guard case .connected = prev.connectionState else { return prev }
                        if let name = name {
                            var new = prev
                            new.name = .success(name)
                            return new
                        } else {
                            var new = prev
                            new.name = .failure(PeripheralModelFailure(description: "No name"))
                            return new
                        }
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        peripheral.didReadRSSI
            .sink { [weak self] resp in
                guard let self else { return }
                
                Task {
                    await self.stateDidUpdateSubject.change { prev in
                        guard case .connected = prev.connectionState else { return prev }
                        if let rssi = resp.rssi {
                            var new = prev
                            new.rssi = .success(rssi)
                            return new
                        } else {
                            var new = prev
                            new.rssi = .failure(PeripheralModelFailure(wrapping: resp.error))
                            return new
                        }
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        let cancellables = mutableCancellables
        Task { await self.store(cancellables: cancellables) }
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables = self.cancellables.union(cancellables)
    }
    
    
    public func connect() {
        Task {
            await stateDidUpdateSubject.change { prev in
                switch prev.connectionState {
                case .disconnected, .connectionFailed:
                    // T3, T6
                    var new = prev
                    new.connectionState = .connecting
                    return new
                default:
                    return prev
                }
            }
            centralManager.connect(peripheral)
        }
    }
    
    
    public func disconnect() {
        Task {
            await stateDidUpdateSubject.change { prev in
                switch prev.connectionState {
                case .connected:
                    // T7
                    var new = prev
                    new.connectionState = .disconnecting
                    return new
                default:
                    return prev
                }
            }
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}
