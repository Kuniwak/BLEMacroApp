import Foundation
import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothTestable
import ModelFoundation



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


public enum PeripheralDiscoveryModelState: Equatable {
    case idle(requestedDiscovery: Bool)
    case ready
    case discovering([AnyPeripheralModel])
    case discovered([AnyPeripheralModel])
    case discoveryFailed(PeripheralDiscoveryModelFailure)

    
    public static func initialState() -> Self {
        .idle(requestedDiscovery: false)
    }


    public var models: Result<[AnyPeripheralModel]?, PeripheralDiscoveryModelFailure> {
        switch self {
        case .discovering(let peripherals), .discovered(let peripherals):
            return .success(peripherals)
        case .idle, .ready:
            return .success(nil)
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
        case .idle(requestedDiscovery: let flag):
            return ".idle(requestedDiscovery: \(flag))"
        case .ready:
            return ".ready"
        case .discovering(let peripherals):
            return ".discovering(\(peripherals.map(\.state.description).joined(separator: ", "))"
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
        case .idle(requestedDiscovery: let flag):
            return ".idle(requestedDiscovery: \(flag))"
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


public protocol PeripheralDiscoveryModelProtocol: StateMachineProtocol where State == PeripheralDiscoveryModelState {
    func startScan() async
    func stopScan() async
}


extension PeripheralDiscoveryModelProtocol {
    nonisolated public func eraseToAny() -> AnyPeripheralDiscoveryModel {
        AnyPeripheralDiscoveryModel(self)
    }
}


public actor AnyPeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    private let base: any PeripheralDiscoveryModelProtocol
    
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }

    
    public init(_ base: any PeripheralDiscoveryModelProtocol) {
        self.base = base
    }
    
    
    public func startScan() async {
        await base.startScan()
    }
    
    
    public func stopScan() async {
        await base.stopScan()
    }
}



public actor PeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    private let centralManager: any CentralManagerProtocol
    
    nonisolated public var state: State { stateDidChangeSubject.projected }
    nonisolated private let stateDidChangeSubject: ProjectedValueSubject<PeripheralDiscoveryModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<PeripheralDiscoveryModelState, Never>
    nonisolated public let dispatchQueue = DispatchQueue(label: "PeripheralDiscoveryModel")
    
    private var cancellables = Set<AnyCancellable>()
    private var x: Int = 0
    
    
    public init(observing centralManager: any CentralManagerProtocol, startsWith initialState: PeripheralDiscoveryModelState) {
        self.centralManager = centralManager
        
        let stateDidChangeSubject = ProjectedValueSubject<PeripheralDiscoveryModelState, Never>(initialState)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        centralManager.didUpdateState
            .receive(on: dispatchQueue)
            .dropFirst() // XXX: Ignore an event that occurs at the subscribing.
            .sink { [weak self] state in
                guard let self else { return }
                Task {
                    await self.stateDidChangeSubject.change { prev in
                        switch (state, prev) {
                        case (.poweredOn, .idle(requestedDiscovery: false)):
                            return .ready
                        case (.poweredOn, .idle(requestedDiscovery: true)):
                            Task { await self.scan() }
                            return .discovering([])
                        case (.poweredOn, _):
                            return prev
                        case (.poweredOff, _):
                            return .discoveryFailed(.powerOff)
                        case (.unknown, _), (.resetting, _):
                            return .idle(requestedDiscovery: false)
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
            .receive(on: dispatchQueue)
            .sink { [weak self] resp in
                guard let self else { return }
                
                Task {
                    await self.stateDidChangeSubject.change { prev in
                        switch prev {
                        case .idle, .ready, .discoveryFailed:
                            return prev
                        case .discovering, .discovered:
                            switch prev.models {
                            case .success(let models):
                                let newModel = PeripheralModel(
                                    representing: resp.peripheral,
                                    withRSSI: resp.rssi,
                                    withAdvertisementData: resp.advertisementData,
                                    connectingWith: ConnectionModel(
                                        centralManager: centralManager,
                                        peripheral: resp.peripheral,
                                        isConnectable: isConnectable(fromAdvertisementData: resp.advertisementData)
                                    )
                                )
                                
                                var newModels = models ?? []
                                newModels.append(newModel.eraseToAny())
                                return .discovering(newModels)
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
    
    
    private func todo(i: Int) {
        self.x = i
    }
    
    
    private func store(cancellable: AnyCancellable) {
        self.cancellables.insert(cancellable)
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables.formUnion(cancellables)
    }
    
    
    public func startScan() async {
        await stateDidChangeSubject.change { prev in
            switch prev {
            case .ready, .discovered, .discoveryFailed:
                Task { self.scan() }
                return .discovering([])
            case .idle(requestedDiscovery: false):
                return .idle(requestedDiscovery: true)
            case .idle(requestedDiscovery: true), .discovering:
                return prev
            }
        }
    }
    
    
    private func scan() {
        self.centralManager.scanForPeripherals(withServices: nil)
    }
    
    
    public func stopScan() async {
        await stateDidChangeSubject.change { prev in
            switch prev {
            case .idle, .ready, .discoveryFailed, .discovered:
                return prev
            case .discovering(let models):
                self.centralManager.stopScan()
                return .discovered(models)
            }
        }
    }
}
