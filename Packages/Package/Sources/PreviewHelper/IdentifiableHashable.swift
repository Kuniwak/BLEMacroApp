public struct Previewable<T>: CustomStringConvertible {
    public let value: T
    public let description: String
    
    
    public init(_ value: T, describing description: String) {
        self.value = value
        self.description = description
    }
}


extension Previewable: Equatable {
    public static func == (lhs: Previewable<T>, rhs: Previewable<T>) -> Bool {
        lhs.description == rhs.description
    }
}


extension Previewable: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
}


extension Previewable: Identifiable {
    public var id: String {
        description
    }
}
