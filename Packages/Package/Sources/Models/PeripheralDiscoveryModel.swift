import Foundation
import Combine
import ConcurrentCombine
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
            return ".discovering([\(peripherals.count) peripherals])"
        case .discovered(let peripherals):
            return ".discovered([\(peripherals.count) peripherals])"
        case .discoveryFailed(let error):
            return ".discoveryFailed(\(error.description))"
        }
    }
}


public protocol PeripheralDiscoveryModelProtocol: StateMachine where State == PeripheralDiscoveryModelState {
    func startScan()
    func stopScan()
}


extension PeripheralDiscoveryModelProtocol {
    nonisolated public func eraseToAny() -> AnyPeripheralDiscoveryModel {
        AnyPeripheralDiscoveryModel(self)
    }
}


public actor AnyPeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    private let base: any PeripheralDiscoveryModelProtocol
    
    nonisolated public var initialState: State { base.initialState }
    nonisolated public var stateDidUpdate: AnyPublisher<State, Never> { base.stateDidUpdate }

    
    public init(_ base: any PeripheralDiscoveryModelProtocol) {
        self.base = base
    }
    
    
    public func startScan() {
        Task { await base.startScan() }
    }
    
    
    public func stopScan() {
        Task { await base.stopScan() }
    }
}



public actor PeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    private let centralManager: any CentralManagerProtocol
    
    nonisolated public let initialState: State
    
    private let stateDidUpdateSubject: ConcurrentValueSubject<PeripheralDiscoveryModelState, Never>
    nonisolated public let stateDidUpdate: AnyPublisher<PeripheralDiscoveryModelState, Never>
    
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing centralManager: any CentralManagerProtocol) {
        self.centralManager = centralManager
        let initialState: State = .idle
        self.initialState = initialState
        
        let stateDidUpdateSubject = ConcurrentValueSubject<PeripheralDiscoveryModelState, Never>(initialState)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        centralManager.didUpdateState
            .sink { [weak self] state in
                guard let self else { return }
                
                Task {
                    await self.stateDidUpdateSubject.change { prev in
                        switch (state, prev) {
                        case (.poweredOn, .idle):
                            return .ready
                        case (.poweredOn, _):
                            return prev
                        case (.poweredOff, _):
                            return .discoveryFailed(.powerOff)
                        case (.unknown, _), (.resetting, _):
                            return .idle
                        case (.unauthorized, _):
                            return .discoveryFailed(.unauthorized)
                        case (.unsupported, _):
                            return .discoveryFailed(.unsupported)
                        default:
                            return prev
                        }
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        centralManager.didDiscoverPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                
                Task {
                    await self.stateDidUpdateSubject.change { prev in
                        switch prev {
                        case .idle, .ready, .discoveryFailed:
                            return prev
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
                            switch prev.models {
                            case .success(let models):
                                return .discovering(models + [newModel.eraseToAny()])
                            case .failure(let error):
                                return .discoveryFailed(.unspecified("\(error)"))
                            }
                        }
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        let cancellables = mutableCancellables
        Task { await self.store(cancellables: cancellables) }
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables.formUnion(cancellables)
    }
    
    
    public func startScan() {
        Task {
            await stateDidUpdateSubject.change { prev in
                switch prev {
                case .ready, .discovered, .discoveryFailed:
                    centralManager.scanForPeripherals(withServices: nil)
                    return .discovering([])
                case .idle, .discovering:
                    return prev
                }
            }
        }
    }
    
    
    public func stopScan() {
        Task {
            await stateDidUpdateSubject.change { prev in
                switch prev {
                case .idle, .ready, .discoveryFailed, .discovered:
                    return prev
                case .discovering(let models):
                    centralManager.stopScan()
                    return .discovered(models)
                }
            }
        }
    }
}
