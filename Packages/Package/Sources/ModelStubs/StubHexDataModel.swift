import Foundation
import Combine
import ModelFoundation
import Models


public final actor StubHexDataModel: HexDataModelProtocol {
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<State, Never>
    
    
    public init(startsWith initialState: State) {
        let stateDidChangeSubject = CurrentValueSubject<State, Never>(initialState)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func updateHexString(with string: String) {}
}
