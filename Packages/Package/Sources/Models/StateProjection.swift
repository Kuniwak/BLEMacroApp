import Foundation
import Combine


public class StateProjection<State>: ObservableObject {
    public var state: State
    
    nonisolated public let objectWillChange: AnyPublisher<Void, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init<P: Publisher>(projecting publisher: P, startsWith initialState: State) where P.Output == State, P.Failure == Never {
        self.state = initialState
        
        var mutableCancellables = Set<AnyCancellable>()
        
        objectWillChange = publisher
            .map { _ in () }
            .eraseToAnyPublisher()

        publisher
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .assign(to: \.state, on: self)
            .store(in: &mutableCancellables)
        
        cancellables = mutableCancellables
    }
}


extension StateProjection {
    public static func project<S: StateMachine>(stateMachine: S) -> StateProjection<State> where S.State == State {
        let publisher = stateMachine.stateDidChange
        let initialValue = stateMachine.initialState
        return StateProjection<State>(projecting: publisher, startsWith: initialValue)
    }
}
