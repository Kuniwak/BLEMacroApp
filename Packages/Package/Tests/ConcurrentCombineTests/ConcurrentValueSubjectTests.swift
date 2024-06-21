import Testing
import XCTest
import Combine
import ConcurrentCombine



final class ConcurrentValueSubjectTests: XCTestCase {
    func test() async throws {
        let subject = ConcurrentValueSubject<Int, Never>(0)
        let recorder = Recorder(observing: subject)

        Task {
            await subject.change { $0 + 1 }
            await subject.change { $0 + 1 }
            await subject.change { $0 + 1 }
            subject.send(completion: .finished)
        }
        
        let values = try await recorder.values(timeout: 1)
        XCTAssertEqual(values, [0, 1, 2, 3])
    }
}
