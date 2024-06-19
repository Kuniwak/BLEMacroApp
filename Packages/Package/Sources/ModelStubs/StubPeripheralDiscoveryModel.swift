import Combine
import Models



public actor StubPeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    nonisolated public let initialState: State
    nonisolated public let stateDidUpdateSubject: CurrentValueSubject<PeripheralDiscoveryModelState, Never>
    nonisolated public let stateDidUpdate: AnyPublisher<Models.PeripheralDiscoveryModelState, Never>

    
    public init(state: PeripheralDiscoveryModelState = .makeStub()) {
        self.initialState = state
        
        let stateDidUpdateSubject = CurrentValueSubject<PeripheralDiscoveryModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
    }
    
    
    public func startScan() {}
    public func stopScan() {}
}


extension PeripheralDiscoveryModelState {
    public static func makeStub() -> Self {
        .discoveryFailed(.init(description: "TEST"))
    }
    
    public static func makeSuccessfulStub() -> Self {
        .discovered([
            StubPeripheralModel().eraseToAny(),
            StubPeripheralModel().eraseToAny()
        ])
    }
}
