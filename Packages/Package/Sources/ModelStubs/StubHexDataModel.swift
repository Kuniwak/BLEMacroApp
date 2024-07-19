import Foundation
import Combine
import ModelFoundation
import Models


public final actor StubHexDataModel: HexDataModelProtocol {
    nonisolated public var state: Result<Data, Models.HexDataModelFailure> { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<Result<Data, Models.HexDataModelFailure>, Never>
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<Result<Data, HexDataModelFailure>, Never>
    
    
    public init(startsWith initialState: State) {
        let stateDidChangeSubject = CurrentValueSubject<Result<Data, HexDataModelFailure>, Never>(initialState)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func update(byString string: String) {}
}
