import Foundation
import CoreBluetooth
import BLEInternal
import BLEAssignedNumbers


public enum ManufacturerData: Equatable {
    case knownName(String, Data)
    case data(Data)
    
    
    public static func from(advertisementData: [String: Any]) -> ManufacturerData? {
        if let manufacturerRawData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            return ManufacturerCatalog.from(data: manufacturerRawData)
        } else {
            return nil
        }
    }
}


extension ManufacturerData: CustomStringConvertible {
    public var description: String {
        switch self {
        case .knownName(let name, let data):
            return ".knownName(\(name), \(data.count) bytes)"
        case .data(let data):
            return ".data(\(data.count) bytes)"
        }
    }
}


extension ManufacturerData: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .knownName(let name, let data):
            return ".knownName(\(name), \(HexEncoding.upper.encode(data: data))"
        case .data(let data):
            return ".data(\(HexEncoding.upper.encode(data: data)))"
        }
    }
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
