import Combine
import Models



public class StubPeripheralDiscoveryModel: PeripheralDiscoveryModelProtocol {
    public var state: PeripheralDiscoveryModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            self.objectWillChange.send()
            stateDidUpdateSubject.value = newValue
        }
    }
    public let objectWillChange = ObjectWillChangePublisher()
    public let stateDidUpdateSubject: CurrentValueSubject<PeripheralDiscoveryModelState, Never>
    public let stateDidUpdate: AnyPublisher<Models.PeripheralDiscoveryModelState, Never>

    
    public init(state: PeripheralDiscoveryModelState = .makeStub()) {
        let stateDidUpdateSubject = CurrentValueSubject<PeripheralDiscoveryModelState, Never>(state)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
    }
    
    
    public func startScan() {
    }
    
    
    public func stopScan() {
    }
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
