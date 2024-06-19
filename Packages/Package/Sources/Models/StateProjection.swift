import Foundation
import Combine


public protocol StateMachine<State>: Actor {
    associatedtype State
    nonisolated var initialState: State { get }
    nonisolated var stateDidUpdate: AnyPublisher<State, Never> { get }
}


public class StateProjection<State>: ObservableObject {
    public var state: State { stateDidUpdateSubject.value }
    
    private let stateDidUpdateSubject: CurrentValueSubject<State, Never>
    nonisolated public let objectWillChange: AnyPublisher<Void, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init<S: StateMachine<State>>(projecting stateMachine: S) {
        let stateDidUpdateSubject = CurrentValueSubject<State, Never>(stateMachine.initialState)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        
        var mutableCancellables = Set<AnyCancellable>()
        
        stateMachine.stateDidUpdate
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .assign(to: \.value, on: stateDidUpdateSubject)
            .store(in: &mutableCancellables)
        
        objectWillChange = stateDidUpdateSubject
            .map { _ in () }
            .eraseToAnyPublisher()
        
        cancellables = mutableCancellables
    }
}
