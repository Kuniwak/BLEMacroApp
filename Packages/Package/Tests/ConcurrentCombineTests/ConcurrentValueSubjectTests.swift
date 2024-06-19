import Testing
import Combine
import ConcurrentCombine


@Test private func concurrentValueSubjectInit() async throws {
    let subject = ConcurrentValueSubject<Int, Never>(0)
    let recorder = subject.startRecord()

    Task {
        await subject.change { $0 + 1 }
        await subject.change { $0 + 1 }
        await subject.change { $0 + 1 }
        await subject.send(completion: .finished)
    }
    
    let values = try await recorder.values(timeout: 1)
    #expect(values == [0, 1, 2, 3])
}
