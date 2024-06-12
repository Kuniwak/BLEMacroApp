import Foundation


public struct TimeoutError: Error, CustomStringConvertible {
    public let description: String
    
    public init(_ interval: TimeInterval) {
        self.description = "Timeout after \(interval) seconds"
    }
}


extension Task {
    public func timeout(_ interval: TimeInterval) async throws -> Success {
        try await withThrowingTaskGroup(of: Success.self) { group in
            group.addTask {
                try await Task<Never, Never>.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                throw TimeoutError(interval)
            }
            
            group.addTask {
                return try await self.value
            }
            
            let value = try await group.next()!
            group.cancelAll()
            return value
        }
    }
}
