import CoreBluetooth
import BLEAssignedNumbers


public enum DescriptorCatalog {
    public static func from(cbuuid: CBUUID) -> (any AssignedNumberProtocol)? {
        guard let uuid = cbuuid.uuid else { return nil }
        return descriptorMap[uuid]
    }
    
    
    private static let descriptorMap = Dictionary(
        uniqueKeysWithValues: AssignedNumbers.Descriptors.all.map { ($0.uuid(), $0) }
    )
}
