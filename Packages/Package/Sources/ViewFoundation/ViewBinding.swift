import SwiftUI
import Combine
import ModelFoundation


public class ViewBinding<State, StateMachine: StateMachineProtocol<State>>: ObservableObject {
    @Published public private(set) var state: State
    public let source: StateMachine
    public var cancellable: AnyCancellable? = nil
    
    
    public init(source: StateMachine) {
        self.state = source.state
        self.source = source
        self.cancellable = source.stateDidChange
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)
    }
}
