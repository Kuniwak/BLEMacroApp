import Testing
import TaskExtensions


@Test private func emptySome() async throws {
    let tasks = [Task<Int, any Error>]()
    let actual = try await Task.all(tasks)
    #expect(actual.isEmpty == true)
}


@Test private func emptyNever() async {
    let tasks = [Task<Int, Never>]()
    let actual = await Task.all(tasks)
    #expect(actual.isEmpty == true)
}


@Test private func severalSome() async throws {
    let tasks = [Task<Int, any Error>]()
    let actual = try await Task.all(tasks)
    #expect(actual.isEmpty == true)
}


@Test private func severalNever() async {
    let tasks: [Task<Int, Never>] = [
        Task { 1 },
        Task {
            try! await Task.sleep(nanoseconds: UInt64(1_000_000))
            return 2
        },
    ]
    let actual = await Task.all(tasks)
    #expect(actual == [1, 2])
}


@Test private func severalNeverReversed() async throws {
    let tasks: [Task<Int, any Error>] = [
        Task {
            try await Task.sleep(nanoseconds: UInt64(1_000_000))
            return 1
        },
        Task { 2 },
    ]
    let actual = try await Task.all(tasks)
    #expect(actual == [1, 2])
}
