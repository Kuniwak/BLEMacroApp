import XCTest
import Combine
import ConcurrentCombine



final class CurrentValueSubjectTests: XCTestCase {
    func test() async throws {
        let subject = CurrentValueSubject<Int, Never>(0)
        let recorder = subject.startRecord()

        Task {
            subject.value += 1
            subject.value += 1
            subject.value += 1
            subject.send(completion: .finished)
        }
        
        let values = try await recorder.values(timeout: 1)
        XCTAssertEqual(values, [0, 1, 2, 3])
    }
}
