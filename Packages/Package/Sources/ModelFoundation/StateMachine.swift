import Combine


public protocol StateMachineProtocol<State>: Actor, CustomReflectable, CustomStringConvertible, CustomDebugStringConvertible {
    associatedtype State: CustomStringConvertible & CustomDebugStringConvertible
    nonisolated var state: State { get }
    nonisolated var stateDidChange: AnyPublisher<State, Never> { get }
}


extension StateMachineProtocol {
    nonisolated public var description: String { state.description }
}


extension StateMachineProtocol {
    nonisolated public var debugDescription: String { state.debugDescription }
}


extension StateMachineProtocol {
    nonisolated public var customMirror: Mirror {
        Mirror(self, children: ["state": state])
    }
}
