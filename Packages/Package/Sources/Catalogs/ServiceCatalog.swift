import CoreBluetooth
import BLEAssignedNumbers


public enum ServiceCatalog {
    public static func from(cbuuid: CBUUID) -> (any AssignedNumberProtocol)? {
        guard let uuid = cbuuid.uuid else { return nil }
        return serviceMap[uuid]
    }
    
    
    private static let serviceMap = Dictionary(
        uniqueKeysWithValues: AssignedNumbers.ServiceUuids.all.map { ($0.uuid(), $0) }
    )
}
