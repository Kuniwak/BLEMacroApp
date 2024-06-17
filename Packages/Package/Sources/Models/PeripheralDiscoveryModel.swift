import Foundation
import Combine
import CoreBluetooth
import CoreBluetoothTestable



public enum PeripheralDiscoveryModelFailure: Error, Equatable {
    case unauthorized
    case unsupported
    case powerOff
    case unspecified(String)
    
    
    public init(description: String) {
        self = .unspecified(description)
    }
    
    
    public init(wrapping error: any Error) {
        self = .unspecified("\(error)")
    }
    
    
    public init(wrapping error: (any Error)?) {
        if let error {
            self = .unspecified("\(error)")
        } else {
            self = .unspecified("nil")
        }
    }
    
    
    public var isRecoverable: Bool {
        switch self {
        case .unsupported:
            return false
        case .unauthorized, .powerOff:
            return true
        case .unspecified:
            // NOTE: Assuming that internal errors are recoverable
            return true
        }
    }
}


extension PeripheralDiscoveryModelFailure: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unauthorized:
            return ".unauthorized"
        case .powerOff:
            return ".powerOff"
        case .unsupported:
            return ".unsupported"
        case .unspecified(let description):
            return ".unspecified(\(description))"
        }
    }
}


public enum PeripheralDiscoveryModelState {
    case idle
    case ready
    case discovering([AnyPeripheralModel])
    case discovered([AnyPeripheralModel])
    case discoveryFailed(PeripheralDiscoveryModelFailure)

    
    public static func initialState() -> Self {
        .idle
    }


    public var models: Result<[AnyPeripheralModel], PeripheralDiscoveryModelFailure> {
        switch self {
        case .discovering(let peripherals), .discovered(let peripherals):
            return .success(peripherals)
        case .idle, .ready:
            return .success([])
        case .discoveryFailed(let error):
            return .failure(error)
        }
    }
    
    
    public var isScanning: Bool {
        switch self {
        case .discovering:
            return true
        case .idle, .ready, .discoveryFailed, .discovered:
            return false
        }
    }
    
    
    public var canStartScan: Bool {
        switch self {
        case .ready, .discovered, .discoveryFailed(.unspecified):
            return true
        case .idle, .discovering, .discoveryFailed(.powerOff), .discoveryFailed(.unauthorized), .discoveryFailed(.unsupported):
            return false
        }
    }
    
    
    public var canStopScan: Bool {
        switch self {
        case .idle, .ready, .discoveryFailed, .discovered:
            return false
        case .discovering:
            return true
        }
    }
}


extension PeripheralDiscoveryModelState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle:
            return ".idle"
        case .ready:
            return ".ready"
        case .discovering(let peripherals):
            return ".discovering([\(peripherals.map(\.state.description).joined(separator: ", "))])"
        case .discovered(let peripherals):
            return ".discovered([\(peripherals.map(\.state.description).joined(separator: ", "))])"
        case .discoveryFailed(let error):
            return ".discoveryFailed(\(error.description))"
        }
    }
}


extension PeripheralDiscoveryModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .idle:
            return ".idle"
        case .ready:
            return ".ready"
        case .discovering(let peripherals):
            return ".discovering([\(peripherals.count) peripherals])"
        case .discovered(let peripherals):
            return ".discovered([\(peripherals.count) peripherals])"
        case .discoveryFailed(let error):
            return ".discoveryFailed(\(error.description))"
        }
    }
}


public protocol PeripheralDiscoveryModelProtocol: ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    var state: PeripheralDiscoveryModelState { get }
    var stateDidUpdate: AnyPublisher<PeripheralDiscoveryModelState, Never> { get }
    func startScan()
    func stopScan()
}


extension PeripheralDiscoveryModelProtocol {
    public func eraseToAny() -> AnyPeripheralDiscoveryModel {
        AnyPeripheralDiscoveryModel(self)
    }
}


public class AnyPeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    private let base: any PeripheralDiscoveryModelProtocol
    
    public var state: PeripheralDiscoveryModelState { base.state }
    public var stateDidUpdate: AnyPublisher<PeripheralDiscoveryModelState, Never> { base.stateDidUpdate }
    public var objectWillChange: ObservableObjectPublisher { base.objectWillChange }

    
    public init(_ base: any PeripheralDiscoveryModelProtocol) {
        self.base = base
    }
    
    
    public func startScan() {
        base.startScan()
    }
    
    
    public func stopScan() {
        base.stopScan()
    }
}



public class PeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    private let centralManager: any CentralManagerProtocol
    
    public private(set) var state: PeripheralDiscoveryModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            objectWillChange.send()
            stateDidUpdateSubject.value = newValue
        }
    }
    
    private let stateDidUpdateSubject: CurrentValueSubject<PeripheralDiscoveryModelState, Never>
    public let stateDidUpdate: AnyPublisher<PeripheralDiscoveryModelState, Never>
    public let objectWillChange = ObservableObjectPublisher()
    
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing centralManager: any CentralManagerProtocol) {
        self.centralManager = centralManager
        
        let stateDidUpdateSubject = CurrentValueSubject<PeripheralDiscoveryModelState, Never>(.idle)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
        self.centralManager.didUpdateState
            .sink { [weak self] state in
                guard let self else { return }
                
                switch (state, self.state) {
                case (.poweredOn, .idle):
                    self.state = .ready
                case (.poweredOn, _):
                    break
                case (.poweredOff, _):
                    self.state = .discoveryFailed(.powerOff)
                case (.unknown, _), (.resetting, _):
                    self.state = .idle
                case (.unauthorized, _):
                    self.state = .discoveryFailed(.unauthorized)
                case (.unsupported, _):
                    self.state = .discoveryFailed(.unsupported)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        self.centralManager.didDiscoverPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                
                switch self.state {
                case .idle, .ready, .discoveryFailed:
                    break
                case .discovering, .discovered:
                    let newModel = PeripheralModel(
                        startsWith: .initialState(
                            uuid: resp.peripheral.identifier,
                            name: resp.peripheral.name,
                            rssi: resp.rssi,
                            advertisementData: resp.advertisementData
                        ),
                        centralManager: centralManager,
                        peripheral: resp.peripheral
                    )
                    switch self.state.models {
                    case .success(let models):
                        self.state = .discovering(models + [newModel.eraseToAny()])
                    case .failure(let error):
                        self.state = .discoveryFailed(.unspecified("\(error)"))
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    
    public func startScan() {
        switch self.state {
        case .ready, .discovered, .discoveryFailed:
            self.state = .discovering([])
            centralManager.scanForPeripherals(withServices: nil)
        case .idle, .discovering:
            break
        }
    }
    
    
    public func stopScan() {
        switch self.state {
        case .idle, .ready, .discoveryFailed, .discovered:
            break
        case .discovering(let models):
            centralManager.stopScan()
            self.state = .discovered(models)
        }
    }
}
