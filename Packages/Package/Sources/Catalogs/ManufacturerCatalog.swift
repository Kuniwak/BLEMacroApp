import Foundation
import BLEAssignedNumbers


public enum ManufacturerData: Equatable {
    case knownName(String, Data)
    case data(Data)
}


public enum ManufacturerCatalog {
    public static func from(data: Data) -> ManufacturerData {
        if let assignedNumber = manufacturerToName[ManufacturerID(data[0], data[1])] {
            return .knownName(assignedNumber.name, data.dropFirst(2))
        }
        return .data(data)
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
