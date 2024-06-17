import Foundation
import Combine
import BLEInternal
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs


public struct PeripheralModelFailure: Error, CustomStringConvertible {
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


public enum ServiceDiscoveryState {
    case notConnectable
    case disconnected([AnyServiceModel]?)
    case connectionFailed(PeripheralModelFailure, [AnyServiceModel]?)
    case connecting(shouldDiscover: Bool, [AnyServiceModel]?)
    case connected([AnyServiceModel]?)
    case discovering
    case discovered([AnyServiceModel])
    case discoverFailed(PeripheralModelFailure)
    case disconnecting([AnyServiceModel]?)

    
    public var services: [AnyServiceModel]? {
        switch self {
        case .disconnected(.some(let services)), .connecting(shouldDiscover: _, .some(let services)), .connected(.some(let services)), .disconnecting(.some(let services)), .discovered(let services), .connectionFailed(_, .some(let services)):
            return services
        case .disconnected(.none), .connecting(shouldDiscover: _, .none), .connected(.none), .discovering, .discoverFailed, .notConnectable, .disconnecting(.none), .connectionFailed(_, .none):
            return nil
        }
    }
    
    
    public var canConnect: Bool {
        switch self {
        case .notConnectable, .connected, .discovering, .disconnecting, .connecting:
            return false
        case .disconnected, .discoverFailed, .discovered, .connectionFailed:
            return true
        }
    }
    
    
    public var isConnected: Bool {
        switch self {
        case .connected, .discovered, .discovering, .discoverFailed:
            return true
        case .disconnected, .connecting, .disconnecting, .notConnectable, .connectionFailed:
            return false
        }
    }
}


extension ServiceDiscoveryState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected(.none):
            return ".disconnected(nil)"
        case .connecting(shouldDiscover: let shouldDiscover, .none):
            return ".connecting(shouldDiscover: \(shouldDiscover), nil)"
        case .disconnecting(.none):
            return ".disconnecting(nil)"
        case .connected(.none):
            return ".connected(nil)"
        case .discovering:
            return ".discovering"
        case .discoverFailed(let error):
            return ".discoverFailed(\(error))"
        case .discovered(let services):
            return ".discovered([\(services.map(\.state.description).joined(separator: ", "))])"
        case .disconnecting(.some(let services)):
            return ".disconnecting([\(services.map(\.state.description).joined(separator: ", "))])"
        case .disconnected(.some(let services)):
            return ".disconnected([\(services.map(\.state.description).joined(separator: ", "))])"
        case .connecting(shouldDiscover: let shouldDiscover, .some(let services)):
            return ".connecting(shouldDiscover: \(shouldDiscover), [\(services.map(\.state.description).joined(separator: ", "))])"
        case .connected(.some(let services)):
            return ".connected([\(services.map(\.state.description).joined(separator: ", "))])"
        case .connectionFailed(let error, .none):
            return ".connectionFailed(\(error), nil)"
        case .connectionFailed(let error, .some(let services)):
            return ".connectionFailed(\(error), [\(services.map(\.state.description).joined(separator: ", "))])"
        case .notConnectable:
            return ".notConnectable"
        }
    }
}


extension ServiceDiscoveryState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .disconnected(.none):
            return ".disconnected(nil)"
        case .connecting(shouldDiscover: let shouldDiscover, .none):
            return ".connecting(shouldDiscover: \(shouldDiscover), nil)"
        case .disconnecting(.none):
            return ".disconnecting(nil)"
        case .connected(.none):
            return ".connected(nil)"
        case .discovering:
            return ".discovering"
        case .discoverFailed(let error):
            return ".discoverFailed(\(error))"
        case .discovered(let services):
            return ".discovered([\(services.count) services])"
        case .disconnecting(.some(let services)):
            return ".disconnecting([\(services.count) services])"
        case .disconnected(.some(let services)):
            return ".disconnected([\(services.count) services])"
        case .connecting(shouldDiscover: let shouldDiscover, .some(let services)):
            return ".connecting(shouldDiscover: \(shouldDiscover), [\(services.count) services])"
        case .connected(.some(let services)):
            return ".connected([\(services.count) services])"
        case .connectionFailed(let error, .none):
            return ".connectionFailed(\(error), nil)"
        case .connectionFailed(let error, .some(let services)):
            return ".connectionFailed(\(error), [\(services.count) services])"
        case .notConnectable:
            return ".notConnectable"
        }
    }
}


extension PeripheralModelState: Identifiable {
    public var id: UUID { uuid }
}


public struct PeripheralModelState {
    public var uuid: UUID
    public var discoveryState: ServiceDiscoveryState
    public var rssi: Result<NSNumber, PeripheralModelFailure>
    public var name: Result<String?, PeripheralModelFailure>
    public var manufacturerData: ManufacturerData?

    
    public init(
        uuid: UUID,
        discoveryState: ServiceDiscoveryState,
        rssi: Result<NSNumber, PeripheralModelFailure>,
        name: Result<String?, PeripheralModelFailure>,
        isConnectable: Bool,
        manufacturerData: ManufacturerData?
    ) {
        self.uuid = uuid
        self.discoveryState = discoveryState
        self.rssi = rssi
        self.name = name
        self.manufacturerData = manufacturerData
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
            discoveryState: isConnectable ? /* T2 */ .disconnected(nil) : /* T2 */ .notConnectable,
            rssi: .success(rssi),
            name: .success(name),
            isConnectable: isConnectable,
            manufacturerData: manufacturerData
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
        
        return "PeripheralModelState(uuid: \(uuid), name: \(name), rssi: \(rssi), manufacturerData: \(manufacturerData), discoveryState: \(discoveryState.description))"
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
        
        return "PeripheralModelState(uuid: \(uuid), name: \(name), rssi: \(rssi), manufacturerData: \(manufacturerData), discoveryState: \(discoveryState.debugDescription))"
    }
}


public protocol PeripheralModelProtocol: Identifiable, ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    var state: PeripheralModelState { get }
    var stateDidUpdate: AnyPublisher<PeripheralModelState, Never> { get }
    
    func connect()
    func disconnect()
    func discoverServices()
}


extension PeripheralModelProtocol {
    public func eraseToAny() -> AnyPeripheralModel {
        AnyPeripheralModel(self)
    }
}


public class AnyPeripheralModel: PeripheralModelProtocol {
    private let base: any PeripheralModelProtocol
    
    public var state: PeripheralModelState { base.state }
    public var stateDidUpdate: AnyPublisher<PeripheralModelState, Never> { base.stateDidUpdate }
    public var objectWillChange: ObservableObjectPublisher { base.objectWillChange }
    
    
    public init(_ base: any PeripheralModelProtocol) {
        self.base = base
    }
    
    
    public func connect() {
        base.connect()
    }
    
    
    public func disconnect() {
        base.disconnect()
    }
    
    
    public func discoverServices() {
        base.discoverServices()
    }
}


// ```marmaid
// stateDiagram-v2
//     state ".notConnectable" as notconnectable
//     state ".disconnected(nil)" as disconnected_nil
//     state ".disconnected(services)" as disconnected_services
//     state ".connectionFailed(error, nil)" as connectionfailed_nil
//     state ".connectionFailed(error, services)" as connectionfailed_services
//     state ".connecting(shouldDiscover: false, nil)" as connecting_false_nil
//     state ".connecting(shouldDiscover: true, nil)" as connecting_true_nil
//     state ".connecting(shouldDiscover: false, services)" as connecting_false_services
//     state ".connecting(shouldDiscover: true, services)" as connecting_true_services
//     state ".connected(nil)" as connected_nil
//     state ".connected(services)" as connected_services
//     state ".discovering" as discovering
//     state ".discovered(services)" as discovered
//     state ".discoverFailed(error)" as discoverfailed
//     state ".disconnecting(nil)" as disconnecting_nil
//     state ".disconnecting(services)" as disconnecting_services
//
//     [*] --> notconnectable: T1
//     [*] --> disconnected_nil: T2
//     disconnected_nil --> connecting_false_nil: T3 connect
//     disconnected_nil --> connecting_true_nil: T4 discoverServices
//     connecting_false_nil --> connected_nil: T5
//     connecting_false_nil --> connectionfailed_nil: T6
//     connectionfailed_nil --> connecting_false_nil: T7 connect
//     connectionfailed_nil --> connecting_true_nil: T8 discoverServices
//     connecting_true_nil --> discovering: T9
//     connecting_true_nil --> connectionfailed_nil: T10
//     connected_nil --> discovering: T11 discoverServices
//     connected_nil --> disconnecting_nil: T12 disconnect
//     discovering --> discovered: T13
//     discovering --> discoverfailed: T14
//     discoverfailed --> disconnecting_nil: T15 disconnect
//     disconnecting_nil --> disconnected_nil: T16
//     discovered --> discovering: T17 discoverServices
//     discovered --> disconnecting_services: T18 disconnect
//     disconnecting_services --> disconnected_services: T19
//     disconnected_services --> connecting_false_services: T20 connect
//     disconnected_services --> connecting_true_services: T21 discoverServices
//     connecting_false_services --> connected_services: T22
//     connecting_false_services --> connectionfailed_services: T23
//     connecting_true_services --> discovering: T24
//     connecting_true_services --> connectionfailed_services: T25
//     connectionfailed_services --> connecting_false_services: T26 connect
//     connectionfailed_services --> connecting_true_services: T27 discoverServices
//     connected_services --> disconnecting_services: T27 disconnect
//     connected_services --> discovering: T29 discoverServices
// ```
public class PeripheralModel: PeripheralModelProtocol {
    private let peripheral: any PeripheralProtocol
    private let centralManager: any CentralManagerProtocol
    
    private let stateDidUpdateSubject: CurrentValueSubject<PeripheralModelState, Never>
    public let stateDidUpdate: AnyPublisher<PeripheralModelState, Never>
    
    public let objectWillChange = ObservableObjectPublisher()
    
    
    public var state: PeripheralModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            objectWillChange.send()
            stateDidUpdateSubject.value = newValue
        }
    }
    
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(
        startsWith initialState: PeripheralModelState,
        centralManager: any CentralManagerProtocol,
        peripheral: any PeripheralProtocol
    ) {
        self.centralManager = centralManager
        self.peripheral = peripheral
        
        let didUpdateSubject = CurrentValueSubject<PeripheralModelState, Never>(initialState)
        self.stateDidUpdateSubject = didUpdateSubject
        self.stateDidUpdate = didUpdateSubject.eraseToAnyPublisher()
        
        centralManager.didConnectPeripheral
            .sink { [weak self] peripheral in
                guard let self else { return }
                guard peripheral.identifier == self.state.uuid else { return }
                
                switch self.state.discoveryState {
                case .connecting(shouldDiscover: let shouldDiscovery, let services):
                    // T5, T22, T9, T24
                    self.state.discoveryState = .connected(services)
                    if shouldDiscovery {
                        self.discoverServices()
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        centralManager.didFailToConnectPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.peripheral.identifier == self.state.uuid else { return }
                
                switch self.state.discoveryState {
                case .connecting(shouldDiscover: _, let services):
                    // T6, T23, T10, T25
                    self.state.discoveryState = .connectionFailed(.init(wrapping: resp.error), services)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        centralManager.didDisconnectPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.peripheral.identifier == self.state.uuid else { return }
                
                // T16, T19
                let services = self.state.discoveryState.services
                self.state.discoveryState = .disconnected(services)
            }
            .store(in: &cancellables)
        
        peripheral.didUpdateRSSI
            .sink { [weak self] resp in
                guard let self else { return }
                
                if let rssi = resp.rssi {
                    self.state.rssi = .success(rssi)
                } else {
                    self.state.rssi = .failure(PeripheralModelFailure(wrapping: resp.error))
                }
            }
            .store(in: &cancellables)
        
        peripheral.didUpdateName
            .sink { [weak self] name in
                guard let self else { return }
                
                if let name = name {
                    self.state.name = .success(name)
                } else {
                    self.state.name = .failure(PeripheralModelFailure(description: "No name"))
                }
            }
            .store(in: &cancellables)
        
        peripheral.didReadRSSI
            .sink { [weak self] resp in
                guard let self else { return }
                
                if let rssi = resp.rssi {
                    self.state.rssi = .success(rssi)
                } else {
                    self.state.rssi = .failure(PeripheralModelFailure(wrapping: resp.error))
                }
            }
            .store(in: &cancellables)
        
        peripheral.didDiscoverServices
            .sink { [weak self] resp in
                guard let self else { return }
                
                switch self.state.discoveryState {
                case .discovering:
                    if let services = resp.services {
                        let newServices = services.map {
                            ServiceModel(
                                startsWith: .initialState(fromServiceUUID: $0.uuid),
                                peripheral: self.peripheral,
                                service: $0
                            ).eraseToAny()
                        }
                        // T13
                        self.state.discoveryState = .discovered(newServices)
                    } else {
                        // T14
                        self.state.discoveryState = .discoverFailed(.init(wrapping: resp.error))
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    
    public func connect() {
        switch state.discoveryState {
        case .disconnected(let services), .connectionFailed(_, let services):
            // T3, T7, T20, T26
            self.state.discoveryState = .connecting(shouldDiscover: false, services)
            centralManager.connect(peripheral)
        default:
            break
        }
    }
    
    
    public func disconnect() {
        switch self.state.discoveryState {
        case .discovered(let services):
            // T18
            self.state.discoveryState = .disconnecting(services)
            centralManager.cancelPeripheralConnection(peripheral)
        case .connected(let services):
            // T12, T27
            self.state.discoveryState = .disconnecting(services)
            centralManager.cancelPeripheralConnection(peripheral)
        case .discoverFailed:
            // T15
            self.state.discoveryState = .disconnecting(nil)
            centralManager.cancelPeripheralConnection(peripheral)
        default:
            break
        }
    }
    
    
    public func discoverServices() {
        switch self.state.discoveryState {
        case .disconnected(let services), .connectionFailed(_, let services):
            // T4, T21, T8, T27
            state.discoveryState = .connecting(shouldDiscover: true, services)
            centralManager.connect(peripheral)
        case .discovered, .connected:
            // T17, T11, T29
            state.discoveryState = .discovering
            peripheral.discoverServices(nil)
        default:
            break
        }
    }
}


extension PeripheralModel: Identifiable {
    public var id: UUID { state.uuid }
}
