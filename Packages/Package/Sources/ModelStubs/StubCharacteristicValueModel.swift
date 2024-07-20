import CoreBluetooth
import Models


extension CharacteristicValueState {
    public static func makeStub(
        properties: CBCharacteristicProperties = [],
        value: Data = Data(),
        error: CharacteristicValueModelFailure? = .init(description: "TEST")
    ) -> Self {
        .init(properties: properties, value: value, error: error)
    }
    
    
    public static func makeSuccessfulStub(
        properties: CBCharacteristicProperties = [.read, .write],
        value: Data = Data()
    ) -> Self {
        .init(properties: properties, value: value, error: nil)
    }
}


extension CBCharacteristicProperties {
    public static var allCases: Self {
        return .broadcast
            .union(.read)
            .union(.writeWithoutResponse)
            .union(.write)
            .union(.notify)
            .union(.indicate)
            .union(.authenticatedSignedWrites)
            .union(.extendedProperties)
            .union(.notifyEncryptionRequired)
            .union(.indicateEncryptionRequired)
    }
}
