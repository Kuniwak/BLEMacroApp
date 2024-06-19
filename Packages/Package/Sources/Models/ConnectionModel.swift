import Foundation
import Combine
import BLEInternal
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs
import ConcurrentCombine


public struct ConnectionModelFailure: Error, Equatable, CustomStringConvertible {
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


public func isConnectable(fromAdvertisementData advertisementData: [String: Any]) -> Bool {
    if let flag = advertisementData[CBAdvertisementDataIsConnectable] as? Bool {
        return flag
    } else {
        // NOTE: Assume connectable if not specified.
        return true
    }
}



public enum ConnectionModelState: Equatable {
    case notConnectable
    case disconnected
    case connectionFailed(ConnectionModelFailure)
    case connecting
    case connected
    case disconnecting
    
    
    public static func initialState(isConnectable: Bool) -> Self {
        if isConnectable {
            return .disconnected
        } else {
            return .notConnectable
        }
    }
    
    
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


extension ConnectionModelState: CustomStringConvertible {
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


public protocol ConnectionModelProtocol: StateMachine, Identifiable where State == ConnectionModelState {
    var state: State { get async }
    
    func connect()
    func disconnect()
}


extension ConnectionModelProtocol {
    nonisolated public func eraseToAny() -> AnyConnectionModel {
        AnyConnectionModel(self)
    }
}


public actor AnyConnectionModel: ConnectionModelProtocol {
    private let base: any ConnectionModelProtocol
    
    public var state: ConnectionModelState {
        get async { await base.state }
    }
    nonisolated public var stateDidChange: AnyPublisher<ConnectionModelState, Never> { base.stateDidChange }
    nonisolated public var initialState: ConnectionModelState { base.initialState }

    
    public init(_ base: any ConnectionModelProtocol) {
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
public actor ConnectionModel: ConnectionModelProtocol {
    private let peripheral: any PeripheralProtocol
    private let centralManager: any CentralManagerProtocol
    nonisolated public let id: UUID
    
    public var state: ConnectionModelState {
        get async { await stateDidChangeSubject.value }
    }
    
    private let stateDidChangeSubject: ConcurrentValueSubject<ConnectionModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<ConnectionModelState, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    nonisolated public let initialState: ConnectionModelState
    
    
    public init(
        centralManager: any CentralManagerProtocol,
        peripheral: any PeripheralProtocol,
        isConnectable: Bool
    ) {
        self.centralManager = centralManager
        self.peripheral = peripheral
        self.id = peripheral.identifier
        
        let initialState: State = .initialState(isConnectable: isConnectable) // T1, T2
        self.initialState = initialState
        let didUpdateSubject = ConcurrentValueSubject<ConnectionModelState, Never>(initialState)
        self.stateDidChangeSubject = didUpdateSubject
        self.stateDidChange = didUpdateSubject.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        centralManager.didConnectPeripheral
            .sink { [weak self] peripheral in
                guard let self else { return }
                guard peripheral.identifier == self.id else { return }
                
                Task {
                    await self.stateDidChangeSubject.change { prev in
                        guard case .connecting = prev else { return prev }
                        // T4
                        return .connected
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        centralManager.didFailToConnectPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.peripheral.identifier == self.id else { return }
                
                Task {
                    await self.stateDidChangeSubject.change { prev in
                        guard case .connecting = prev else { return prev }
                        // T5
                        return.connectionFailed(.init(wrapping: resp.error))
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        centralManager.didDisconnectPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.peripheral.identifier == self.id else { return }
                
                Task {
                    await self.stateDidChangeSubject.change { prev in
                        // T8
                        return .disconnected
                    }
                }
            }
            .store(in: &mutableCancellables)
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables = self.cancellables.union(cancellables)
    }
    
    
    public func connect() {
        Task {
            await stateDidChangeSubject.change { prev in
                switch prev {
                case .disconnected, .connectionFailed:
                    // T3, T6
                    return .connecting
                default:
                    return prev
                }
            }
            centralManager.connect(peripheral)
        }
    }
    
    
    public func disconnect() {
        Task {
            await stateDidChangeSubject.change { prev in
                switch prev {
                case .connected:
                    // T7
                    return .disconnecting
                default:
                    return prev
                }
            }
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}
