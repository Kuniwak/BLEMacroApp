import Combine
import Models


public class StubPeripheralSearchModel: PeripheralSearchModelProtocol {
    public let stateDidUpdateSubject: CurrentValueSubject<PeripheralSearchModelState, Never>
    public var state: PeripheralSearchModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    public let stateDidUpdate: AnyPublisher<PeripheralSearchModelState, Never>
    
    public let searchQuery: CurrentValueSubject<String, Never>
    public let objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
    
    
    public init(state: PeripheralSearchModelState = .makeStub()) {
        let stateDidUpdateSubject = CurrentValueSubject<PeripheralSearchModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
        self.searchQuery = CurrentValueSubject<String, Never>(state.searchQuery)
    }
    
    
    public func startScan() {
    }
    
    public func stopScan() {
    }
}


extension PeripheralSearchModelState {
    public static func makeStub(
        discoveryState: PeripheralDiscoveryModelState = .makeStub(),
        searchQuery: String = ""
    ) -> Self {
        .init(discoveryState: discoveryState, searchQuery: searchQuery)
    }
}
