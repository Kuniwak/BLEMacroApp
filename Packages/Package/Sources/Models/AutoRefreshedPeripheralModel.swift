import Foundation
import Combine
import Dispatch


public protocol AutoRefreshedPeripheralModelProtocol: PeripheralModelProtocol {
    nonisolated func setAutoRefresh(_ enabled: Bool)
}


extension AutoRefreshedPeripheralModelProtocol {
    nonisolated public func eraseToAny() -> AnyAutoRefreshedPeripheralModel {
        AnyAutoRefreshedPeripheralModel(wrapping: self)
    }
}


public final actor AnyAutoRefreshedPeripheralModel: AutoRefreshedPeripheralModelProtocol {
    nonisolated private let base: any AutoRefreshedPeripheralModelProtocol
    
    nonisolated public var state: PeripheralModelState { base.state }
    nonisolated public var connection: any ConnectionModelProtocol { base.connection }
    nonisolated public var stateDidChange: AnyPublisher<PeripheralModelState, Never> { base.stateDidChange }
    nonisolated public var id: UUID { base.id }
    
    
    public init(wrapping base: any AutoRefreshedPeripheralModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func setAutoRefresh(_ enabled: Bool) { base.setAutoRefresh(enabled) }
    nonisolated public func readRSSI() { base.readRSSI() }
    nonisolated public func discover() { base.discover() }
    nonisolated public func connect() { base.connect() }
    nonisolated public func disconnect() { base.disconnect() }
}


public final actor AutoRefreshedPeripheralModel: AutoRefreshedPeripheralModelProtocol {
    nonisolated private let base: any PeripheralModelProtocol
    
    nonisolated public var state: PeripheralModelState { base.state }
    nonisolated public var connection: any ConnectionModelProtocol { base.connection }
    nonisolated public var stateDidChange: AnyPublisher<PeripheralModelState, Never> { base.stateDidChange }
    nonisolated public var id: UUID { base.id }
    private var timer: Timer? = nil
    private let interval: TimeInterval
    
    
    public init(wrapping base: any PeripheralModelProtocol, withTimeInterval interval: TimeInterval) {
        self.base = base
        self.interval = interval
    }
    
    
    deinit {
        self.timer?.invalidate()
    }
    
    
    nonisolated public func setAutoRefresh(_ enabled: Bool) {
        Task {
            await setAutoRefreshInternal(enabled)
        }
    }
    
    
    private func setAutoRefreshInternal(_ enabled: Bool) {
        if enabled && self.timer == nil {
            self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                guard let self, self.state.connection.isConnected else { return }
                self.readRSSI()
            }
        } else if !enabled, let timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    
    nonisolated public func readRSSI() {
        base.readRSSI()
    }
    
    
    nonisolated public func discover() {
        base.discover()
    }
    
    
    nonisolated public func connect() {
        base.connect()
    }
    
    
    nonisolated public func disconnect() {
        base.disconnect()
    }
}
