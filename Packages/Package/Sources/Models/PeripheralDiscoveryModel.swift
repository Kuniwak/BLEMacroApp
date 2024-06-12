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
            return "Unauthorized"
        case .powerOff:
            return "PowerOff"
        case .unsupported:
            return "Unsupported"
        case .unspecified(let description):
            return "Unspecified: \(description)"
        }
    }
}


public enum PeripheralDiscoveryModelState {
    case idle
    case awaitingReady
    case ready
    case discovering([any PeripheralModelProtocol])
    case discovered([any PeripheralModelProtocol])
    case discoveryFailed(PeripheralDiscoveryModelFailure)


    public var models: Result<[any PeripheralModelProtocol], PeripheralDiscoveryModelFailure> {
        switch self {
        case .discovering(let peripherals), .discovered(let peripherals):
            return .success(peripherals)
        case .idle, .awaitingReady, .ready:
            return .success([])
        case .discoveryFailed(let error):
            return .failure(error)
        }
    }
}


public protocol PeripheralDiscoveryModelProtocol {
    var state: PeripheralDiscoveryModelState { get }
    var stateDidUpdate: AnyPublisher<PeripheralDiscoveryModelState, Never> { get }
    func discover()
}


public class PeripheralsDiscoveryModel: PeripheralDiscoveryModelProtocol {
    private let centralManager: any CentralManagerProtocol
    
    public private(set) var state: PeripheralDiscoveryModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    
    private let stateDidUpdateSubject: CurrentValueSubject<PeripheralDiscoveryModelState, Never>
    public let stateDidUpdate: AnyPublisher<PeripheralDiscoveryModelState, Never>
    
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
                case (.poweredOn, .awaitingReady):
                    self.centralManager.scanForPeripherals(withServices: nil)
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
                case .awaitingReady, .discovering, .discovered:
                    let newModel = PeripheralModel(
                        startsWith: .initialState(name: resp.peripheral.name, rssi: resp.rssi, advertisementData: resp.advertisementData),
                        centralManager: centralManager,
                        peripheral: resp.peripheral
                    )
                    switch self.state.models {
                    case .success(let models):
                        self.state = .discovering(models + [newModel])
                    case .failure(let error):
                        self.state = .discoveryFailed(.unspecified("\(error)"))
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    
    public func discover() {
        switch self.state {
        case .idle:
            self.state = .awaitingReady
        case .ready, .discovered, .discoveryFailed:
            self.state = .discovering([])
            centralManager.scanForPeripherals(withServices: nil)
        case .discovering, .awaitingReady:
            break
        }
    }
}
