import Foundation
import Combine
import ConcurrentCombine
import ModelFoundation
import Catalogs
import BLEAssignedNumbers
import BLEInternal


public struct IBeaconType: Hashable, Sendable, RawRepresentable {
    public typealias RawValue = Data
    
    public let byte0: UInt8
    public let byte1: UInt8
    public var rawValue: Data { Data([byte0, byte1]) }
    
    
    public init(_ byte0: UInt8, _ byte1: UInt8) {
        self.byte0 = byte0
        self.byte1 = byte1
    }
    
    
    public init?(rawValue: Data) {
        guard rawValue.count == 2 else { return nil }
        self.byte0 = rawValue[0]
        self.byte1 = rawValue[1]
    }
    
    
    public static let proximity = IBeaconType(0x02, 0x15)
}


extension IBeaconType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .proximity:
            return "Proximity"
            
        default:
            return String(format: "Unknown(%02X%02X)", byte0, byte1)
        }
    }
}


public struct IBeaconRegion: Hashable, Sendable, RawRepresentable {
    public typealias RawValue = Data
    
    public let byte0: UInt8
    public let byte1: UInt8
    public var rawValue: Data { Data([byte0, byte1]) }
    
    
    public init(_ byte0: UInt8, _ byte1: UInt8) {
        self.byte0 = byte0
        self.byte1 = byte1
    }
    
    
    public init?(rawValue: Data) {
        guard rawValue.count == 2 else { return nil }
        self.byte0 = rawValue[0]
        self.byte1 = rawValue[1]
    }
    
    
    public static let proximity = IBeaconType(0x02, 0x15)
}


extension IBeaconRegion: CustomStringConvertible {
    public var description: String {
        String(format: "%02X%02X", byte0, byte1)
    }
}


public struct IBeaconFailure: Error, Equatable, Sendable, CustomStringConvertible {
    public let description: String
    
    
    public init(_ description: String) {
        self.description = description
    }
}


public typealias IBeaconState = Result<IBeaconData, IBeaconFailure>


public struct IBeaconData: Equatable, Sendable {
    public let type: IBeaconType
    public let proximityUUID: UUID
    public let major: IBeaconRegion
    public let minor: IBeaconRegion
    public let measuredPower: Int8
    
    
    public init(type: IBeaconType, proximityUUID: UUID, major: IBeaconRegion, minor: IBeaconRegion, measuredPower: Int8) {
        self.type = type
        self.proximityUUID = proximityUUID
        self.major = major
        self.minor = minor
        self.measuredPower = measuredPower
    }
    
    
    public static func from(manufacturer: ManufacturerData) -> IBeaconState {
        switch manufacturer {
        case .data(let data):
            return .failure(.init("Unknown manufacturer: \(BLEInternal.HexEncoding.upper.encode(data: data))"))
        case .knownName(let name, let data):
            guard (name.byte1, name.byte2) == (AssignedNumbers.MemberUuids.appleInc.uuidByte3, AssignedNumbers.MemberUuids.appleInc.uuidByte4) else {
                return .failure(.init("Manufacturer must be Apple Inc., but got: \(name)"))
            }
            guard data.count == 23 else {
                return .failure(.init("Invalid manufacturer payload length: \(data.count)"))
            }
            
            return .success(.init(
                type: IBeaconType(data[0], data[1]),
                proximityUUID: UUID(uuid: (
                    data[2],
                    data[3],
                    data[4],
                    data[5],
                    data[5],
                    data[7],
                    data[8],
                    data[9],
                    data[10],
                    data[11],
                    data[12],
                    data[13],
                    data[14],
                    data[15],
                    data[16],
                    data[17]
                )),
                major: IBeaconRegion(data[18], data[19]),
                minor: IBeaconRegion(data[20], data[21]),
                measuredPower: Int8(bitPattern: data[22])
            ))
        }
    }
}


public protocol IBeaconModelProtocol: StateMachineProtocol<IBeaconState> {}


public extension IBeaconModelProtocol {
    nonisolated func eraseToAny() -> AnyIBeaconModel {
        return AnyIBeaconModel(self)
    }
}


public final actor AnyIBeaconModel: IBeaconModelProtocol {
    nonisolated private let base: any IBeaconModelProtocol
    nonisolated public var state: IBeaconState { base.state }
    nonisolated public var stateDidChange: AnyPublisher<IBeaconState, Never> { base.stateDidChange }
    
    
    public init(_ base: any IBeaconModelProtocol) {
        self.base = base
    }
}


public final actor IBeaconModel: IBeaconModelProtocol {
    nonisolated private let model: any PeripheralModelProtocol
    nonisolated public var state: IBeaconState {
        guard let manufacturerData = model.state.manufacturerData else { return .failure(.init("No manufacturer data")) }
        return IBeaconData.from(manufacturer: manufacturerData)
    }
    nonisolated public let stateDidChange: AnyPublisher<IBeaconState, Never>
    
    
    public init(observing model: any PeripheralModelProtocol) {
        self.model = model
        self.stateDidChange = model.stateDidChange
            .map { state in
                guard let manufacturerData = state.manufacturerData else { return .failure(.init("No manufacturer data")) }
                return IBeaconData.from(manufacturer: manufacturerData)
            }
            .eraseToAnyPublisher()
    }
}
