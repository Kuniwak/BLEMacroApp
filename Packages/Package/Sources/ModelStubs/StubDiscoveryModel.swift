import Models
import CoreBluetooth


extension DiscoveryModelState where ID == CBUUID, S == ServiceModelState, M == AnyServiceModel, E == PeripheralModelFailure {
    public static func makeStub() -> Self {
        .discoveryFailed(
            .init(description: "TEST"),
            nil
        )
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .discovered(StateMachineArray([
            StubServiceModel(state: .makeSuccessfulStub()).eraseToAny(),
            StubServiceModel(state: .makeSuccessfulStub()).eraseToAny(),
        ]))
    }
}


extension DiscoveryModelState where ID == CBUUID, S == CharacteristicModelState, M == AnyCharacteristicModel, E == ServiceModelFailure {
    public static func makeStub() -> Self {
        .discoveryFailed(
            .init(description: "TEST"),
            nil
        )
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .discovered(StateMachineArray([
            StubCharacteristicModel(state: .makeSuccessfulStub()).eraseToAny(),
            StubCharacteristicModel(state: .makeSuccessfulStub()).eraseToAny(),
        ]))
    }
}


extension DiscoveryModelState where ID == CBUUID, S == DescriptorModelState, M == AnyDescriptorModel, E == CharacteristicModelFailure {
    public static func makeStub() -> Self {
        .discoveryFailed(
            .init(description: "TEST"),
            nil
        )
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .discovered(StateMachineArray([
            StubDescriptorModel(state: .makeStub()).eraseToAny(),
            StubDescriptorModel(state: .makeStub()).eraseToAny(),
        ]))
    }
}
