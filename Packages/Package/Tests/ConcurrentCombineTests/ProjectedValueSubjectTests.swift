import XCTest
import Combine
import ConcurrentCombine



final class ProjectedValueSubjectTests: XCTestCase {
    func test() async throws {
        let subject = ProjectedValueSubject<Int, Never>(0)
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
