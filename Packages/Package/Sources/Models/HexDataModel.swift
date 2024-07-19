import Foundation
import Combine
import ConcurrentCombine
import ModelFoundation
import BLEInternal


public struct HexDataModelFailure: Error, CustomStringConvertible, Equatable, Sendable {
    public let description: String
    
    
    public init(description: String) {
        self.description = description
    }
    
    
    public init(wrapping error: any Error) {
        self.description = "\(error)"
    }
    
    
    public init(wrapping error: (any Error)?) {
        if let error = error {
            self.description = "\(error)"
        } else {
            self.description = "nil"
        }
    }
}


public protocol HexDataModelProtocol: StateMachineProtocol<Result<Data, HexDataModelFailure>> {
    nonisolated func update(byString string: String)
}


extension HexDataModelProtocol {
    nonisolated public func eraseToAny() -> AnyHexDataModel {
        AnyHexDataModel(self)
    }
}


public final actor AnyHexDataModel: HexDataModelProtocol {
    private let base: any HexDataModelProtocol
    
    nonisolated public var state: Result<Data, HexDataModelFailure> { base.state }
    nonisolated public var stateDidChange: AnyPublisher<Result<Data, HexDataModelFailure>, Never> { base.stateDidChange }
    
    
    public init(_ base: any HexDataModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func update(byString string: String) {
        base.update(byString: string)
    }
}


public final actor HexDataModel: HexDataModelProtocol {
    nonisolated public var state: Result<Data, HexDataModelFailure> { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<Result<Data, HexDataModelFailure>, Never>
    nonisolated public let stateDidChangeSubject: ConcurrentValueSubject<Result<Data, HexDataModelFailure>, Never>
    
    
    public init(startsWith initialState: State) {
        let stateDidChangeSubject = ConcurrentValueSubject<Result<Data, HexDataModelFailure>, Never>(initialState)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func update(byString string: String) {
        Task {
            await stateDidChangeSubject.change { _ in
                switch HexEncoding.decode(hexString: string) {
                case .failure(let error):
                    return .failure(.init(wrapping: error))
                case .success((data: let data, _)):
                    return .success(data)
                }
            }
        }
    }
}
