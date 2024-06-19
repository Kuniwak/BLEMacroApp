import Combine


public actor ConcurrentValueSubject<Output, Failure: Error>: Publisher {
    public typealias Output = Output
    public typealias Failure = Failure
    private let subject: CurrentValueSubject<Output, Failure>
    nonisolated public let initialValue: Output
    
    
    public var value: Output { subject.value }
    
    
    public init(_ value: Output) {
        self.initialValue = value
        self.subject = CurrentValueSubject<Output, Failure>(value)
    }
    
    
    public func change(_ f: (Output) -> Output) {
        subject.value = f(subject.value)
    }
    
    
    public func send(completion: Subscribers.Completion<Failure>) {
        subject.send(completion: completion)
    }
    
    
    nonisolated public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        Task { await subject.receive(subscriber: subscriber) }
    }
}
