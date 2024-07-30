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


public enum HexDataModelState: Equatable, Sendable {
    case success(Data)
    case failure(HexDataModelFailure)
}


extension HexDataModelState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success(let data):
            return ".success(\(data))"
        case .failure(let error):
            return ".failure(\(error.description))"
        }
    }
}


extension HexDataModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .success(let data):
            return ".success"
        case .failure(let error):
            return ".failure"
        }
    }
}


public protocol HexDataModelProtocol: StateMachineProtocol<HexDataModelState> {
    nonisolated func updateHexString(with string: String)
}


extension HexDataModelProtocol {
    nonisolated public func eraseToAny() -> AnyHexDataModel {
        AnyHexDataModel(self)
    }
}


public final actor AnyHexDataModel: HexDataModelProtocol {
    private let base: any HexDataModelProtocol
    
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    
    
    public init(_ base: any HexDataModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func updateHexString(with string: String) {
        base.updateHexString(with: string)
    }
}


public final actor HexDataModel: HexDataModelProtocol {
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    nonisolated public let stateDidChangeSubject: ConcurrentValueSubject<State, Never>
    
    
    public init(startsWith initialState: State) {
        let stateDidChangeSubject = ConcurrentValueSubject<State, Never>(initialState)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func updateHexString(with string: String) {
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
