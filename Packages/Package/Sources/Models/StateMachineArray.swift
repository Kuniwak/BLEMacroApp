import Combine
import ConcurrentCombine


public struct StateMachineArrayElement<ID: Hashable, State, M: StateMachine & Identifiable> where M.State == State, M.ID == ID { 
    public var state: State
    public var stateMachine: M
    
    public init(state: State, stateMachine: M) {
        self.state = state
        self.stateMachine = stateMachine
    }
}


private struct StateMachineArrayState<ID: Hashable, State, M: StateMachine & Identifiable> where M.State == State, M.ID == ID {
    typealias Element = StateMachineArrayElement<ID, State, M>
    private var ids: [ID]
    private var stateMachineMap: [ID: Element]
    
    public var stateMachines: [Element] { ids.map { self.stateMachineMap[$0]! } }
    

    public init(_ stateMachines: [M]) {
        self.ids = stateMachines.map(\.id)
        self.stateMachineMap = Dictionary(uniqueKeysWithValues: stateMachines.map { ($0.id, Element(state: $0.initialState, stateMachine: $0)) })
    }
    
    
    public mutating func append(stateMachine: M) {
        let id = stateMachine.id
        stateMachineMap[id] = Element(state: stateMachine.initialState, stateMachine: stateMachine)
        ids.append(id)
    }
    
    
    public mutating func update(state: State, byID id: ID) {
        var newEntry = stateMachineMap[id]!
        newEntry.state = state
        stateMachineMap[id] = newEntry
    }
}


public actor StateMachineArray<ID: Hashable, S, SM: StateMachine<S> & Identifiable<ID>>: StateMachine {
    public typealias State = [StateMachineArrayElement<ID, S, SM>]
   
    public var state: State {
        get async { await stateDidChangeSubject.value.stateMachines }
    }
    
    private let stateDidChangeSubject: ConcurrentValueSubject<StateMachineArrayState<ID, S, SM>, Never>
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    
    nonisolated public let initialState: State
    private var cancellables = [ID: AnyCancellable]()
    
    
    public init(_ stateMachines: [SM]) {
        let initialState = stateMachines.map { State.Element(state: $0.initialState, stateMachine: $0) }
        self.initialState = initialState
        
        let stateDidChangeSubject = ConcurrentValueSubject<StateMachineArrayState<ID, S, SM>, Never>(.init(stateMachines))
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject
            .map(\.stateMachines)
            .eraseToAnyPublisher()
    }
    
    
    private func store(id: ID, cancellable: AnyCancellable) {
        self.cancellables[id] = cancellable
    }
    
    
    nonisolated public func append(_ newStateMachine: SM) {
        Task {
            let newID = newStateMachine.id
            
            await self.stateDidChangeSubject.change { prev in
                var newState = prev
                newState.append(stateMachine: newStateMachine)
                return newState
            }
            
            let cancellable = newStateMachine.stateDidChange
                .sink { [weak self] state in
                    guard let self = self else { return }
                    
                    Task {
                        await self.stateDidChangeSubject.change { prev in
                            var newState = prev
                            newState.update(state: state, byID: newID)
                            return newState
                        }
                    }
                }
            
            await self.store(id: newID, cancellable: cancellable)
        }
    }
}
