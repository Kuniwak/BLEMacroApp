extension Task where Failure == Never {
    public static func all(_ ts: [Task<Success, Never>]) async -> [Success] {
        return await withTaskGroup(of: (Int, Success).self) { group async in
            for (i, t) in ts.enumerated() {
                group.addTask {
                    (i, await t.value)
                }
            }
            
            var values: [Success?] = Array(repeating: nil, count: ts.count)
            for await (i, value) in group {
                values[i] = value
            }
            
            return (0..<ts.count).map { values[$0]! }
        }
    }
}


extension Task {
    public static func all(_ ts: [Task<Success, Failure>]) async throws -> [Success] {
        return try await withThrowingTaskGroup(of: (Int, Success).self) { group async throws in
            for (i, t) in ts.enumerated() {
                group.addTask {
                    (i, try await t.result.get())
                }
            }
            
            var values: [Success?] = Array(repeating: nil, count: ts.count)
            for try await (i, value) in group {
                values[i] = value
            }
            
            return (0..<ts.count).map { values[$0]! }
        }
    }
}
