import Combine
import ConcurrentCombine
import Models


public actor StubPeripheralSearchModel: PeripheralSearchModelProtocol {
    nonisolated public let initialState: State
    
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<PeripheralSearchModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<PeripheralSearchModelState, Never>
    
    nonisolated public let searchQuery: ConcurrentValueSubject<SearchQuery, Never>
    
    
    public init(state: PeripheralSearchModelState = .makeStub()) {
        self.initialState = state
        
        let stateDidChangeSubject = CurrentValueSubject<PeripheralSearchModelState, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        
        self.searchQuery = ConcurrentValueSubject<SearchQuery, Never>(state.searchQuery)
    }
    
    
    public func startScan() {}
    public func stopScan() {}
}


extension PeripheralSearchModelState {
    public static func makeStub(
        discovery: PeripheralDiscoveryModelState = .makeStub(),
        searchQuery: SearchQuery = SearchQuery(rawValue: "")
    ) -> Self {
        .init(discovery: discovery, searchQuery: searchQuery)
    }
}
