public struct SearchablePeripheralEntries: Equatable, Sendable {
    public var entries: PeripheralEntries
    public var searchQuery: SearchQuery
    
    
    public init(entries: PeripheralEntries, searchQuery: SearchQuery) {
        self.entries = entries
        self.searchQuery = searchQuery
    }
    
    
    public var ordered: [PeripheralEntry] {
        entries.ordered
            .filter { searchQuery.match(state: $0.peripheral.state) }
    }
}


public struct SearchQuery: RawRepresentable, Equatable, Codable, Sendable, ExpressibleByStringLiteral {
    public typealias StringLiteralType = Swift.StringLiteralType
    public typealias ExtendedGraphemeClusterLiteralType = Swift.ExtendedGraphemeClusterType
    public typealias UnicodeScalarLiteralType = UnicodeScalarType
    
    public var rawValue: String
    
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
    
    
    public func match(state: PeripheralModelState) -> Bool {
        let searchQuery = self.rawValue
        if searchQuery.isEmpty { return true }
        
        if state.uuid.uuidString.contains(searchQuery) {
            return true
        }
        
        switch state.name {
        case .success(.some(let name)):
            if name.contains(searchQuery) {
                return true
            }
        case .failure, .success(.none):
            break
        }
        
        return false
    }
}


extension SearchQuery: CustomStringConvertible {
    public var description: String { rawValue }
}
