import Foundation
import BLEAssignedNumbers


public enum ManufacturerCatalog {
    public static func from(data: Data) -> (any AssignedNumberProtocol)? {
        guard data.count >= 2 else { return nil }
        return manufacturerToName[ManufacturerID(data[0], data[1])]
    }

    
    private static let manufacturerToName = Dictionary(
        uniqueKeysWithValues: AssignedNumbers.MemberUuids.all.map { (ManufacturerID($0.uuidByte3, $0.uuidByte4), $0) }
    )


    private struct ManufacturerID: Hashable {
        public let byte3: UInt8
        public let byte4: UInt8
        
        
        public init(_ byte3: UInt8, _ byte4: UInt8) {
            self.byte3 = byte3
            self.byte4 = byte4
        }
    }
}
