import Combine


public protocol StateMachineProtocol<State>: Actor {
    associatedtype State
    nonisolated var state: State { get }
    nonisolated var stateDidChange: AnyPublisher<State, Never> { get }
}
