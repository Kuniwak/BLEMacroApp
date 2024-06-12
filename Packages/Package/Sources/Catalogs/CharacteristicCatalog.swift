import CoreBluetooth
import BLEAssignedNumbers


public enum CharacteristicCatalog {
    public static func from(cbuuid: CBUUID) -> (any AssignedNumberProtocol)? {
        guard let uuid = cbuuid.uuid else { return nil }
        return characteristicMap[uuid]
    }
    
    
    private static let characteristicMap = Dictionary(
        uniqueKeysWithValues: AssignedNumbers.CharacteristicUuids.all.map { ($0.uuid(), $0) }
    )
}
