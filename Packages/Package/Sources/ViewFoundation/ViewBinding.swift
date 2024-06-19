import SwiftUI
import Combine
import ModelFoundation


public class ViewBinding<State, StateMachine: StateMachineProtocol<State>>: ObservableObject {
    public var state: State { source.state }
    public let source: StateMachine
    public let objectWillChange: AnyPublisher<Void, Never>
    
    
    public init(source: StateMachine) {
        self.source = source
        self.objectWillChange = source.stateDidChange
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
