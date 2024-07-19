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
