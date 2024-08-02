public struct BLEMacroDocumentFailure: Error, Equatable, Sendable, CustomStringConvertible {
    public let description: String
    
    public init(description: String) {
        self.description = description
    }
    
    public init(wrapping error: any Error) {
        self.description = "\(error)"
    }
}
