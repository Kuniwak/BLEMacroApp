import Combine


public class ProjectedValueSubject<Output, Failure: Error>: Publisher {
    public typealias Output = Output
    public typealias Failure = Failure
    private let subject: ConcurrentValueSubject<Output, Failure>
    public private(set) var projected: Output
    
    
    public init(_ value: Output) {
        self.projected = value
        self.subject = ConcurrentValueSubject<Output, Failure>(value)
    }
    
    
    public func change(_ f: @escaping (Output) -> Output) async {
        await subject.change(f)
    }
    
    
    nonisolated public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
}
