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
    case disconnected([any ServiceModelProtocol]?)
    case connecting
    case connected
    case discovering
    case discoverFailed(PeripheralModelFailure)
    case discovered([any ServiceModelProtocol])
    case disconnecting
    
    
    public var services: [any ServiceModelProtocol] {
        switch self {
        case .discovered(let services), .disconnected(.some(let services)):
            return services
        case .discovering, .connecting, .connected, .disconnecting, .disconnected(nil), .notConnectable, .discoverFailed:
            return []
        }
    }
    
    
    public var isConnected: Bool {
        switch self {
        case .connected, .discovered, .discovering, .discoverFailed:
            return true
        case .disconnected, .connecting, .disconnecting, .notConnectable:
            return false
        }
    }
    
    
    public var isDisconnected: Bool {
        switch self {
        case .disconnected, .notConnectable:
            return true
        case .connected, .connecting, .disconnecting, .discovering, .discovered, .discoverFailed:
            return false
        }
    }
}


extension PeripheralModelState: CustomStringConvertible {
    public var description: String {
        switch discoveryState {
        case .disconnected(.some(let services)):
            return ".disconnected([\(services.map(\.state.description).joined(separator: ", "))])"
        case .disconnected(nil):
            return ".disconnected"
        case .connecting:
            return ".connecting"
        case .connected:
            return ".connected"
        case .discovering:
            return ".discovering"
        case .discoverFailed(let error):
            return ".discoverFailed(\(error))"
        case .discovered(let services):
            return ".discovered([\(services.map(\.state.description).joined(separator: ", "))])"
        case .disconnecting:
            return ".disconnecting"
        case .notConnectable:
            return ".notConnectable"
        }
    }
}


public struct PeripheralModelState {
    public var discoveryState: ServiceDiscoveryState
    public var rssi: Result<NSNumber, PeripheralModelFailure>
    public var name: Result<String?, PeripheralModelFailure>
    public var manufacturerData: ManufacturerData?
    
    
    public init(
        discoveryState: ServiceDiscoveryState,
        rssi: Result<NSNumber, PeripheralModelFailure>,
        name: Result<String?, PeripheralModelFailure>,
        isConnectable: Bool,
        manufacturerData: ManufacturerData?
    ) {
        self.discoveryState = discoveryState
        self.rssi = rssi
        self.name = name
        self.manufacturerData = manufacturerData
    }
    
    
    public static func initialState(
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
            discoveryState: isConnectable ? .disconnected(nil) : .notConnectable,
            rssi: .success(rssi),
            name: .success(name),
            isConnectable: isConnectable,
            manufacturerData: manufacturerData
        )
    }
}


public protocol PeripheralModelProtocol: Identifiable, ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    var uuid: UUID { get }
    var state: PeripheralModelState { get }
    var stateDidUpdate: AnyPublisher<PeripheralModelState, Never> { get }
    
    func connect()
    func cancelConnection()
    func discoverServices()
}


extension PeripheralModelProtocol {
    public func eraseToAny() -> AnyPeripheralModel {
        AnyPeripheralModel(self)
    }
}


public class AnyPeripheralModel: PeripheralModelProtocol {
    private let base: any PeripheralModelProtocol
    
    
    public var uuid: UUID { base.uuid }
    public var state: PeripheralModelState { base.state }
    public var stateDidUpdate: AnyPublisher<PeripheralModelState, Never> { base.stateDidUpdate }
    public var objectWillChange: ObservableObjectPublisher { base.objectWillChange }
    
    
    public init(_ base: any PeripheralModelProtocol) {
        self.base = base
    }
    
    
    public func connect() {
        base.connect()
    }
    
    
    public func cancelConnection() {
        base.cancelConnection()
    }
    
    
    public func discoverServices() {
        base.discoverServices()
    }
}


public class PeripheralModel: PeripheralModelProtocol {
    private let peripheral: any PeripheralProtocol
    private let centralManager: any CentralManagerProtocol
    
    private let stateDidUpdateSubject: CurrentValueSubject<PeripheralModelState, Never>
    public let stateDidUpdate: AnyPublisher<PeripheralModelState, Never>
    
    public let objectWillChange = ObservableObjectPublisher()
    
    
    public var uuid: UUID { peripheral.identifier }
    
    
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
        
        self.peripheral.didUpdateRSSI
            .sink { [weak self] resp in
                guard let self else { return }
                
                if let rssi = resp.rssi {
                    self.state.rssi = .success(rssi)
                } else {
                    self.state.rssi = .failure(PeripheralModelFailure(wrapping: resp.error))
                }
            }
            .store(in: &cancellables)
        
        self.peripheral.didUpdateName
            .sink { [weak self] name in
                guard let self else { return }
                
                if let name = name {
                    self.state.name = .success(name)
                } else {
                    self.state.name = .failure(PeripheralModelFailure(description: "No name"))
                }
            }
            .store(in: &cancellables)
        
        self.peripheral.didReadRSSI
            .sink { [weak self] resp in
                guard let self else { return }
                
                if let rssi = resp.rssi {
                    self.state.rssi = .success(rssi)
                } else {
                    self.state.rssi = .failure(PeripheralModelFailure(wrapping: resp.error))
                }
            }
            .store(in: &cancellables)
        
        self.peripheral.didDiscoverServices
            .sink { [weak self] resp in
                guard let self else { return }
                
                if let services = resp.services {
                    let newServices = services.map {
                        ServiceModel(
                            startsWith: .initialState(fromServiceUUID: $0.uuid),
                            peripheral: self.peripheral,
                            service: $0
                        )
                    }
                    self.state.discoveryState = .discovered(newServices)
                } else {
                    self.state.discoveryState = .discoverFailed(.init(wrapping: resp.error))
                }
            }
            .store(in: &cancellables)
    }
    
    
    public func connect() {
        guard !state.discoveryState.isDisconnected else { return }
        self.state.discoveryState = .connecting
        centralManager.connect(peripheral)
    }
    
    
    public func cancelConnection() {
        guard state.discoveryState.isConnected else { return }
        self.state.discoveryState = .disconnecting
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    
    public func discoverServices() {
        guard state.discoveryState.isConnected else { return }
        peripheral.discoverServices(nil)
    }
}


extension PeripheralModel: Identifiable {
    public var id: UUID { uuid }
}
