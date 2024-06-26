import Combine


public class ProjectedValueSubject<Output, Failure: Error>: Publisher {
    public typealias Output = Output
    public typealias Failure = Failure
    private let subject: ConcurrentValueSubject<Output, Failure>
    public private(set) var projected: Output
    private var cancellable: AnyCancellable? = nil
    
    
    public init(_ value: Output) {
        self.projected = value
        let subject = ConcurrentValueSubject<Output, Failure>(value)
        self.subject = subject
        
        cancellable = subject
            .sink { _ in
                // Do nothing.
            } receiveValue: { [weak self] value in
                self?.projected = value
            }
    }
    
    
    public func change(_ f: @escaping (Output) -> Output) async {
        await subject.change(f)
    }
    
    
    nonisolated public func send(completion: Subscribers.Completion<Failure>) {
        subject.send(completion: completion)
    }

    
    nonisolated public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
}
