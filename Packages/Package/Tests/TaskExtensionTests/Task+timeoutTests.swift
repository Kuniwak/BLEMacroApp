import Testing
import TaskExtensions


@Test func timeoutSuccess() async throws {
    let task = Task {
        return 42
    }
    let result = try await task.timeout(1)
    #expect(result == 42)
}


@Test func timeoutFailed() async throws {
    let task = Task {
        try await Task.sleep(nanoseconds: UInt64(1_000_000_000))
        return 42
    }
    await #expect(throws: TimeoutError.self) {
        _ = try await task.timeout(0)
    }
}
