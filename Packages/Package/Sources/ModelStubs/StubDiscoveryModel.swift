import Models
import CoreBluetooth


extension DiscoveryModelState where Value == AnyServiceModel, Failure == PeripheralModelFailure {
    public static func makeStub() -> Self {
        .discoveryFailed(
            .init(description: "TEST"),
            nil
        )
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .discovered([
            StubServiceModel(state: .makeSuccessfulStub()).eraseToAny(),
            StubServiceModel(state: .makeSuccessfulStub()).eraseToAny(),
        ])
    }
}


extension DiscoveryModelState where Value == AnyCharacteristicModel, Failure == ServiceModelFailure {
    public static func makeStub() -> Self {
        .discoveryFailed(
            .init(description: "TEST"),
            nil
        )
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .discovered([
            StubCharacteristicModel(state: .makeSuccessfulStub()).eraseToAny(),
            StubCharacteristicModel(state: .makeSuccessfulStub()).eraseToAny(),
        ])
    }
}


extension DiscoveryModelState where Value == AnyDescriptorModel, Failure == CharacteristicModelFailure {
    public static func makeStub() -> Self {
        .discoveryFailed(
            .init(description: "TEST"),
            nil
        )
    }
    
    
    public static func makeSuccessfulStub() -> Self {
        .discovered([
            StubDescriptorModel(state: .makeStub()).eraseToAny(),
            StubDescriptorModel(state: .makeStub()).eraseToAny(),
        ])
    }
}
