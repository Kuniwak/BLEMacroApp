import Combine


public actor ConcurrentValueSubject<Output, Failure: Error>: ObservableObject, Publisher {
    public typealias Output = Output
    public typealias Failure = Failure
    nonisolated private let subject: CurrentValueSubject<Output, Failure>
    
    
    nonisolated public var value: Output {
        get { subject.value }
    }
    
    
    public init(_ value: Output) {
        self.subject = CurrentValueSubject<Output, Failure>(value)
    }
    
    
    public func change(_ f: (Output) -> Output) {
        subject.value = f(subject.value)
    }
    
    
    nonisolated public func send(completion: Subscribers.Completion<Failure>) {
        subject.send(completion: completion)
    }
    
    
    nonisolated public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
}
