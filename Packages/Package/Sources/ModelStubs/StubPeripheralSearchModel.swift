import Combine
import ConcurrentCombine
import Models


public actor StubPeripheralSearchModel: PeripheralSearchModelProtocol {
    nonisolated public let initialState: State
    
    nonisolated public let stateDidUpdateSubject: CurrentValueSubject<PeripheralSearchModelState, Never>
    nonisolated public let stateDidUpdate: AnyPublisher<PeripheralSearchModelState, Never>
    
    nonisolated public let searchQuery: ConcurrentValueSubject<SearchQuery, Never>
    
    
    public init(state: PeripheralSearchModelState = .makeStub()) {
        self.initialState = state
        
        let stateDidUpdateSubject = CurrentValueSubject<PeripheralSearchModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
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
