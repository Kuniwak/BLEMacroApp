import Combine
import Foundation
import TaskExtensions


public class Recorder<Output, Failure: Error> {
    fileprivate private(set) var values = [Output]()
    private var cancellable: AnyCancellable? = nil
    fileprivate private(set) var result: Result<[Output], Failure>? = nil
    
    
    public init<P: Publisher>(observing publisher: P) where P.Output == Output, P.Failure == Failure {
        cancellable = publisher.sink(
            receiveCompletion: { [weak self] completion in
                guard let self else { return }
                
                switch completion {
                case .finished:
                    self.result = .success(self.values)
                case .failure(let e):
                    self.result = .failure(e)
                }
            },
            receiveValue: { [weak self] in
                guard let self else { return }
                self.values.append($0)
            }
        )
    }
    
    
    public func values(timeout: TimeInterval) async throws -> [Output] {
        let deadline = Date.now.addingTimeInterval(timeout)
        
        while true {
            if Date.now > deadline { throw TimeoutError(timeout) }
            
            if let result = result {
                switch result {
                case .success(let values):
                    return values
                case .failure(let e):
                    throw e
                }
            }
            
            try! await Task.sleep(nanoseconds: 1_000_000)
        }
    }
}


extension Publisher {
    public func startRecord() -> Recorder<Output, Failure> {
        Recorder(observing: self)
    }
}
