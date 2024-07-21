import Combine
import ConcurrentCombine
import ModelFoundation
import Models


public final actor StubPeripheralSearchModel: PeripheralSearchModelProtocol {
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated public let stateDidChangeSubject: ConcurrentValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    
    public init(state: State = .makeStub()) {
        let stateDidChangeSubject = ConcurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func startScan() {}
    nonisolated public func stopScan() {}
    nonisolated public func updateSearchQuery(to searchQuery: SearchQuery) {}
}


extension StubPeripheralSearchModel: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}


extension PeripheralSearchModelState {
    public static func makeStub(
        discovery: PeripheralDiscoveryModelState = .makeStub(),
        searchQuery: SearchQuery = SearchQuery(rawValue: "")
    ) -> Self {
        .init(discovery: discovery, searchQuery: searchQuery)
    }
}
