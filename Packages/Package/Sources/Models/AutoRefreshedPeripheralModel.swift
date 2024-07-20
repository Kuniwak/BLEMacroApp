import Foundation
import Combine


public final actor AutoRefreshedPeripheralModel: PeripheralModelProtocol {
    nonisolated private let base: any PeripheralModelProtocol
    
    nonisolated public var state: PeripheralModelState { base.state }
    nonisolated public var connection: any ConnectionModelProtocol { base.connection }
    nonisolated public var stateDidChange: AnyPublisher<PeripheralModelState, Never> { base.stateDidChange }
    nonisolated public var id: UUID { base.id }
    private var timer: Timer? = nil
    
    
    public init(wrapping base: any PeripheralModelProtocol, withTimeInterval interval: TimeInterval) {
        self.base = base
        Task { await self.startPolling(withTimeInterval: interval) }
    }
    
    
    deinit {
        self.timer?.invalidate()
    }
    
    
    private func startPolling(withTimeInterval interval: TimeInterval) {
        self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self, self.state.connection.isConnected else { return }
            self.readRSSI()
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
