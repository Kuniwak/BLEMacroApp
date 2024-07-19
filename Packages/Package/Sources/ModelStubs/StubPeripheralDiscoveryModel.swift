import Combine
import ModelFoundation
import Models



public final actor StubPeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<PeripheralDiscoveryModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<Models.PeripheralDiscoveryModelState, Never>

    
    public init(state: PeripheralDiscoveryModelState = .makeStub()) {
        let stateDidChangeSubject = CurrentValueSubject<PeripheralDiscoveryModelState, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func startScan() {}
    nonisolated public func stopScan() {}
    nonisolated public func refreshState() {}
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
