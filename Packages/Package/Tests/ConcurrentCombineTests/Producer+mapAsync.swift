import Testing
import Combine


@Test
func mapAsyncEmpty() async throws {
    let subject = PassthroughSubject<Int, Never>()
    let recorder = subject
        .mapAsync { $0 + 1 }
        .startRecord()
    
    Task {
        subject.send(completion: .finished)
    }
    
    let values = try await recorder.values(timeout: 1)
    #expect(values == [])
}


@Test
func mapAsyncSeveralSync() async throws {
    let subject = PassthroughSubject<Int, Never>()
    let recorder = subject
        .mapAsync { $0 + 1 }
        .startRecord()
    
    Task {
        subject.send(0)
        subject.send(1)
        subject.send(completion: .finished)
    }
    
    let values = try await recorder.values(timeout: 1)
    #expect(values == [1, 2])
}


@Test
func mapAsyncSeveralAsync() async throws {
    let subject = PassthroughSubject<Int, Never>()
    let recorder = subject
        .mapAsync { i in
            try! await Task.sleep(nanoseconds: 1_000_000 * UInt64(i))
            return i + 1
        }
        .startRecord()
    
    Task {
        subject.send(0)
        subject.send(1)
        subject.send(completion: .finished)
    }
    
    let values = try await recorder.values(timeout: 1)
    #expect(values == [1, 2])
}


@Test
func mapAsyncSeveralAsyncReveresed() async throws {
    let subject = PassthroughSubject<Int, Never>()
    let recorder = subject
        .mapAsync { i in
            try! await Task.sleep(nanoseconds: 1_000_000 * UInt64(i))
            return i + 1
        }
        .startRecord()
    
    Task {
        subject.send(1)
        subject.send(0) // Overtake the first value
        subject.send(completion: .finished)
    }
    
    let values = try await recorder.values(timeout: 1)
    #expect(values == [2])
}
