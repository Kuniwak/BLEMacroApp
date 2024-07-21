import Foundation
import Combine
import CoreBluetoothStub
import Models
import ModelFoundation


public final actor StubAutoRefreshedPeripheralModel: AutoRefreshedPeripheralModelProtocol {
    nonisolated public var state: PeripheralModelState { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<PeripheralModelState, Never>
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<PeripheralModelState, Never>
    nonisolated public let connection: any ConnectionModelProtocol
    nonisolated public let id: UUID
    
    
    public init(state: State = .makeStub(), connection: any ConnectionModelProtocol = StubConnectionModel(), id: UUID = StubUUID.zero) {
        let stateDidChangeSubject = CurrentValueSubject<PeripheralModelState, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        self.connection = connection
        self.id = id
    }
    
    
    nonisolated public func setAutoRefresh(_ enabled: Bool) {}
    nonisolated public func readRSSI() {}
    nonisolated public func discover() {}
    nonisolated public func connect() {}
    nonisolated public func disconnect() {}
}
