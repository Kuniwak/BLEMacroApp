import Combine


// TODO: Rename to StateMachineProtocol to avoid conflict with type arguments
public protocol StateMachine<State>: Actor {
    associatedtype State
    nonisolated var initialState: State { get }
    nonisolated var stateDidChange: AnyPublisher<State, Never> { get }
}
