import Foundation
import Combine
import CoreBluetooth
import CoreBluetoothStub
import Catalogs
import Models


public final actor StubConnectionModel: ConnectionModelProtocol {
    nonisolated public var state: ConnectionModelState { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<ConnectionModelState, Never>
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<ConnectionModelState, Never>
    
    nonisolated public let initialState: ConnectionModelState
    
    
    public init(state: ConnectionModelState = .makeStub()) {
        self.initialState = state
        
        let stateDidChangeSubject = CurrentValueSubject<ConnectionModelState, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func connect() {}
    nonisolated public func disconnect() {}
    nonisolated public func discoverServices() {}
}


extension ConnectionModelState {
    public static func makeStub() -> Self {
        .connectionFailed(.init(description: "TEST"))
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .connected
    }
}
