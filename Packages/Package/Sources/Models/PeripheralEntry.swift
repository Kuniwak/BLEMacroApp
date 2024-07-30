import Foundation


public struct PeripheralEntry: Sendable {
    public let peripheral: any PeripheralModelProtocol
    public let connection: any ConnectionModelProtocol
    
    
    public init(peripheral: any PeripheralModelProtocol, connection: any ConnectionModelProtocol) {
        self.peripheral = peripheral
        self.connection = connection
    }
}


extension PeripheralEntry: Identifiable {
    public var id: UUID { peripheral.id }
}


extension PeripheralEntry: CustomStringConvertible {
    public var description: String {
        return "(peripheral: \(peripheral.description), connection: \(connection.description))"
    }
}


extension PeripheralEntry: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "(peripheral: \(peripheral.debugDescription), connection: \(connection.debugDescription))"
    }
}


extension PeripheralEntry: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.peripheral.id == rhs.peripheral.id
            && lhs.peripheral.state == rhs.peripheral.state
            && lhs.connection.state == rhs.connection.state
    }
}


public struct PeripheralEntries: Equatable, Sendable {
    public var ordered: [PeripheralEntry]
    public var uuids: Set<UUID>
    
    
    public init(ordered: [PeripheralEntry]) {
        self.ordered = []
        self.uuids = Set()
        
        for entry in ordered {
            self.append(entry)
        }
    }
    
    
    public static let empty = PeripheralEntries(ordered: [])
    
    
    public var isEmpty: Bool {
        ordered.isEmpty
    }
    
    
    public mutating func append(_ entry: PeripheralEntry) {
        if uuids.contains(entry.peripheral.id) {
            let index = ordered.firstIndex(where: { $0.peripheral.id == entry.peripheral.id })!
            ordered[index] = entry
        } else {
            ordered.append(entry)
            uuids.insert(entry.peripheral.id)
        }
    }
    
    
    public func filter(_ condition: (PeripheralEntry) -> Bool) -> Self {
        Self(ordered: ordered.filter(condition))
    }
}


extension PeripheralEntries: CustomStringConvertible {
    public var description: String {
        return "[\(ordered.map(\.description).joined(separator: ", "))]"
    }
}


extension PeripheralEntries: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "[\(ordered.map(\.debugDescription).joined(separator: ", "))]"
    }
}
