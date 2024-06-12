import Combine
import Models



public class StubPeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    public var state: PeripheralDiscoveryModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    public let stateDidUpdate: AnyPublisher<PeripheralDiscoveryModelState, Never>
    public let stateDidUpdateSubject: CurrentValueSubject<PeripheralDiscoveryModelState, Never>
    
    
    public init(state: PeripheralDiscoveryModelState = .makeStub()) {
        let stateDidUpdateSubject = CurrentValueSubject<PeripheralDiscoveryModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
    }
    
    
    public func discover() {
    }
}


extension PeripheralDiscoveryModelState {
    public static func makeStub() -> Self {
        .discoveryFailed(.init(description: "TEST"))
    }
}
