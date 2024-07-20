import Combine
import ModelFoundation
import Models


public final actor StubPeripheralDistanceModel: PeripheralDistanceModelProtocol {
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<PeripheralDistanceState, Never>
    nonisolated public var state: PeripheralDistanceState { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<PeripheralDistanceState, Never>
    
    
    public init(startsWith initialState: State = .makeStub()) {
        let stateDidChangeSubject = CurrentValueSubject<PeripheralDistanceState, Never>(initialState)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func update(environmentalFactorTo environmentalFactor: Double) {}
    nonisolated public func update(txPowerTo txPower: Double) {}
}


extension PeripheralDistanceState {
    public static func makeStub(
        distance: Double? = nil,
        environmentalFactor: Double = -1,
        txPower: Double = 0
    ) -> Self {
        .init(distance: distance, environmentalFactor: environmentalFactor, txPower: txPower)
    }
    
    
    public static func makeSuccessfulStub(
        distance: Double? = 10,
        environmentalFactor: Double = 2,
        txPower: Double = -50
    ) -> Self {
        .init(distance: distance, environmentalFactor: environmentalFactor, txPower: txPower)
    }
}
