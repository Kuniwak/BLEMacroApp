import Foundation
import Combine


public protocol StateMachine<State>: Actor {
    associatedtype State
    nonisolated var initialState: State { get }
    nonisolated var stateDidChange: AnyPublisher<State, Never> { get }
}


public class StateProjection<State>: ObservableObject {
    public var state: State
    
    nonisolated public let objectWillChange: AnyPublisher<Void, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init<S: StateMachine<State>>(projecting stateMachine: S) {
        self.state = stateMachine.initialState
        
        var mutableCancellables = Set<AnyCancellable>()
        
        objectWillChange = stateMachine.stateDidChange
            .map { _ in () }
            .eraseToAnyPublisher()

        stateMachine.stateDidChange
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .assign(to: \.state, on: self)
            .store(in: &mutableCancellables)
        
        cancellables = mutableCancellables
    }
}
