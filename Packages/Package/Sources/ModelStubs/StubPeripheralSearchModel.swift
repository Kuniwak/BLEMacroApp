import Combine
import ConcurrentCombine
import ModelFoundation
import Models


public actor StubPeripheralSearchModel: PeripheralSearchModelProtocol {
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<State, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    nonisolated public let searchQuery: ProjectedValueSubject<SearchQuery, Never>
    
    
    public init(state: State = .makeStub()) {
        let stateDidChangeSubject = CurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        
        self.searchQuery = ProjectedValueSubject<SearchQuery, Never>(state.searchQuery)
    }
    
    
    public func startScan() {}
    public func stopScan() {}
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
