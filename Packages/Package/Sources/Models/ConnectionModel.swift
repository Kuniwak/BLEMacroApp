import Foundation
import Combine
import ConcurrentCombine
import BLEInternal
import CoreBluetooth
import CoreBluetoothTestable
import ModelFoundation
import Catalogs


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
            return .disconnected // t1
        } else {
            return .notConnectable // t2
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
    
    
    public var isFailed: Bool {
        switch self {
        case .connectionFailed:
            return true
        case .disconnected, .connecting, .disconnecting, .notConnectable, .connected:
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


extension ConnectionModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notConnectable:
            return ".notConnectable"
        case .disconnected:
            return ".disconnected"
        case .connectionFailed:
            return ".connectionFailed"
        case .connecting:
            return ".connecting"
        case .connected:
            return ".connected"
        case .disconnecting:
            return ".disconnecting"
        }
    }
}


public protocol ConnectionModelProtocol: StateMachineProtocol, Identifiable where State == ConnectionModelState {
    nonisolated func connect()
    nonisolated func disconnect()
}


extension ConnectionModelProtocol {
    nonisolated public func eraseToAny() -> AnyConnectionModel {
        AnyConnectionModel(self)
    }
}


public final actor AnyConnectionModel: ConnectionModelProtocol {
    private let base: any ConnectionModelProtocol
    
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }

    
    public init(_ base: any ConnectionModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func connect() {
        base.connect()
    }
    
    
    nonisolated public func disconnect() {
        base.disconnect()
    }
}



/// ```marmaid
/// stateDiagram-v2
///     state ".notConnectable" as notConnectable
///     state ".disconnected" as disconnected
///     state ".connectionFailed(error)" as connectionFailed
///     state ".connecting" as connecting
///     state ".connected" as connected
///
///     [*] --> notConnectable: t1 tau
///     [*] --> disconnected: t2 tau
///     disconnected --> connecting: t3 connect
///     connecting --> connected: t4 tau
///     connecting --> connectionFailed: t5 tau
///     connectionFailed --> connecting: t6 connect
///     connected --> disconnecting: t7 disconnect
///     disconnecting --> disconnected: t8 tau
/// ```
public final actor ConnectionModel: ConnectionModelProtocol {
    private let peripheral: any PeripheralProtocol
    private let centralManager: any SendableCentralManagerProtocol
    nonisolated public let id: UUID
    
    nonisolated public var state: ConnectionModelState { stateDidChangeSubject.value }
    nonisolated private let stateDidChangeSubject: ConcurrentValueSubject<ConnectionModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<ConnectionModelState, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    nonisolated public let initialState: ConnectionModelState
    
    
    public init(
        centralManager: any SendableCentralManagerProtocol,
        peripheral: any PeripheralProtocol,
        initialState: State
    ) {
        self.centralManager = centralManager
        self.peripheral = peripheral
        self.id = peripheral.identifier
        
        self.initialState = initialState
        let didUpdateSubject = ConcurrentValueSubject<ConnectionModelState, Never>(initialState)
        self.stateDidChangeSubject = didUpdateSubject
        self.stateDidChange = didUpdateSubject.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        centralManager.didConnectPeripheral
            .sink { [weak self] peripheral in
                guard let self else { return }
                guard peripheral.identifier == self.id else { return }
                
                Task { await self.didConnect() }
            }
            .store(in: &mutableCancellables)
        
        centralManager.didFailToConnectPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.peripheral.identifier == self.id else { return }
                
                Task { await self.didFailToConnect(error: resp.error) }
            }
            .store(in: &mutableCancellables)
        
        centralManager.didDisconnectPeripheral
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.peripheral.identifier == self.id else { return }
                
                Task { await self.didDisconnect(error: resp.error) }
            }
            .store(in: &mutableCancellables)
        
        let cancellables = mutableCancellables
        Task { await self.store(cancellables: cancellables) }
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables = self.cancellables.union(cancellables)
    }
    
    
    nonisolated public func connect() {
        Task {
            await stateDidChangeSubject.change { prev in
                switch prev {
                case .disconnected, .connectionFailed:
                    return .connecting // t3, t6
                default:
                    return prev // r1
                }
            }
            await centralManager.connect(peripheral)
        }
    }
    
    
    nonisolated public func disconnect() {
        Task {
            await stateDidChangeSubject.change { prev in
                switch prev {
                case .connected:
                    return .disconnecting // t7
                default:
                    return prev // r2
                }
            }
            await centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    
    private func didConnect() async {
        await stateDidChangeSubject.change { prev in
            guard case .connecting = prev else { return prev }
            return .connected // t4
        }
    }
    
    
    private func didFailToConnect(error: (any Error)?) async {
        await stateDidChangeSubject.change { prev in
            guard case .connecting = prev else { return prev }
            return .connectionFailed(.init(wrapping: error)) // t5
        }
    }
    
    
    private func didDisconnect(error: (any Error)?) async {
        await stateDidChangeSubject.change { prev in
            if let error {
                return .connectionFailed(.init(wrapping: error)) // t5
            } else {
                return .disconnected // t8
            }
        }
    }
}
