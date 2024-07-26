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
    case discovering([AnyPeripheralModel], Set<UUID>)
    case discovered([AnyPeripheralModel], Set<UUID>)
    case discoveryFailed(PeripheralDiscoveryModelFailure)

    
    public static func initialState() -> Self {
        .idle(requestedDiscovery: false)
    }


    public var models: Result<[AnyPeripheralModel]?, PeripheralDiscoveryModelFailure> {
        switch self {
        case .discovering(let peripherals, _), .discovered(let peripherals, _):
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
    
    
    public var isFailed: Bool {
        switch self {
        case .discoveryFailed:
            return true
        case .idle, .ready, .discovering, .discovered:
            return false
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
        case .discovering(let peripherals, _):
            return ".discovering(\(peripherals.map(\.state.description).joined(separator: ", "))"
        case .discovered(let peripherals, _):
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
        case .discovering(let peripherals, _):
            return ".discovering([\(peripherals.count) peripherals])"
        case .discovered(let peripherals, _):
            return ".discovered([\(peripherals.count) peripherals])"
        case .discoveryFailed(let error):
            return ".discoveryFailed(\(error.description))"
        }
    }
}


public protocol PeripheralDiscoveryModelProtocol: StateMachineProtocol where State == PeripheralDiscoveryModelState {
    nonisolated func startScan()
    nonisolated func stopScan()
}


extension PeripheralDiscoveryModelProtocol {
    nonisolated public func eraseToAny() -> AnyPeripheralDiscoveryModel {
        AnyPeripheralDiscoveryModel(self)
    }
}


public final actor AnyPeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    private let base: any PeripheralDiscoveryModelProtocol
    
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }

    
    public init(_ base: any PeripheralDiscoveryModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func startScan() {
        base.startScan()
    }
    
    
    nonisolated public func stopScan() {
        base.stopScan()
    }
}



/// PeripheralDiscoveryModel is a state machine that manages the discovery of peripherals.
/// ```
/// stateDiagram-v2
///     state "idle(requestedDiscovery: false)" as idle_false
///     state "idle(requestedDiscovery: true)" as idle_true
///     state "ready" as ready
///     state "discovering([...])" as discovering
///     state "discovered([...]" as discovered
///     state "discoveryFailed(error)" as error
///     state "discoveryFailed(.unsupported)" as unsupported
///
///     [*] --> idle_false: t0
///     idle_false --> ready: t1_poweredOn
///     idle_false --> idle_true: t2_startScan
///     ready --> discovering: t3_startScan
///     idle_true --> discovering: t4_poweredOn
///     discovering --> discovering: t5_didPeripheralDiscover
///     discovering --> discovered: t6_stopScan
///     discovered --> discovering: t7_startScan
///     idle_false --> unsupported: t8_unsupported
///     idle_true --> unsupported: t9_unsupported
///     idle_false --> error: t10_error
///     idle_true --> error: t11_ error
///     ready --> error: t12_error
///     discovering --> error: t13_error
///     discovered --> error: t14_error
///     error --> error: t15_error
///     error --> ready: t16_poweredOn
/// ```
public final actor PeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    private let centralManager: any SendableCentralManagerProtocol
    
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated private let stateDidChangeSubject: ConcurrentValueSubject<PeripheralDiscoveryModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<PeripheralDiscoveryModelState, Never>
    nonisolated public let dispatchQueue = DispatchQueue(label: "PeripheralDiscoveryModel")
    
    private var cancellables = Set<AnyCancellable>()
    private var discovered = Set<UUID>()
    
    
    public init(observing centralManager: any SendableCentralManagerProtocol, startsWith initialState: PeripheralDiscoveryModelState) {
        self.centralManager = centralManager
        
        let stateDidChangeSubject = ConcurrentValueSubject<PeripheralDiscoveryModelState, Never>(initialState)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        centralManager.didUpdateState
            .receive(on: dispatchQueue)
            .dropFirst() // XXX: Ignore an event that occurs at the subscribing.
            .sink { [weak self] state in
                guard let self else { return }
                Task { await self.update(byState: state) }
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
                        case .discovering(let models, let discovered), .discovered(let models, let discovered):
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

                            if discovered.contains(resp.peripheral.identifier) {
                                var newModels = models
                                let index = newModels.firstIndex(where: { $0.id == resp.peripheral.identifier })!
                                newModels[index] = newModel.eraseToAny()
                                return .discovering(newModels, discovered)
                            } else {
                                var newModels = models
                                newModels.append(newModel.eraseToAny())
                                return .discovering(newModels, discovered.union([resp.peripheral.identifier]))
                            }
                        }
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        let cancellables = mutableCancellables
        Task { await self.store(cancellables: cancellables) }
    }
    
    
    private func update(byState state: CBManagerState) {
        Task {
            await stateDidChangeSubject.change { prev in
                switch (state, prev) {
                case (.poweredOn, .idle(requestedDiscovery: false)):
                    return .ready
                case (.poweredOn, .idle(requestedDiscovery: true)):
                    self.scan()
                    return .discovering([], Set())
                case (.poweredOn, .discoveryFailed(.powerOff)), (.poweredOn, .discoveryFailed(.unauthorized)):
                    return .ready
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
    
    
    private func store(cancellable: AnyCancellable) {
        self.cancellables.insert(cancellable)
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables.formUnion(cancellables)
    }
    
    
    nonisolated public func startScan() {
        Task {
            await stateDidChangeSubject.change { prev in
                switch prev {
                case .ready, .discovered, .discoveryFailed:
                    self.scan()
                    return .discovering([], Set())
                case .idle(requestedDiscovery: false):
                    return .idle(requestedDiscovery: true)
                case .idle(requestedDiscovery: true), .discovering:
                    return prev
                }
            }
        }
    }
    
    
    nonisolated private func scan() {
        self.centralManager.scanForPeripherals(withServices: nil)
    }
    
    
    nonisolated public func stopScan() {
        Task {
            await stateDidChangeSubject.change { prev in
                switch prev {
                case .idle, .ready, .discoveryFailed, .discovered:
                    return prev
                case .discovering(let models, let discovered):
                    self.centralManager.stopScan()
                    return .discovered(models, discovered)
                }
            }
        }
    }
}
