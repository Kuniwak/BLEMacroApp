import Foundation
import CoreBluetooth
import Combine
import Models


public final actor StubCharacteristicStringValueModel: CharacteristicStringValueModelProtocol {
    nonisolated public var state: CharacteristicStringValueState { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<CharacteristicStringValueState, Never>
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<CharacteristicStringValueState, Never>
    
    
    public init(state: CharacteristicStringValueState = .makeStub()) {
        let stateDidChangeSubject = CurrentValueSubject<CharacteristicStringValueState, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
    
    
    nonisolated public func read() {}
    nonisolated public func write(type: CBCharacteristicWriteType) {}
    nonisolated public func updateHexString(with string: String) {}
    nonisolated public func setNotify(_ enabled: Bool) {}
    
    
    nonisolated public func eraseToAny() -> AnyCharacteristicStringValueModel {
        AnyCharacteristicStringValueModel(self)
    }
}


extension CharacteristicStringValueState {
    public static func makeStub(
        properties: CBCharacteristicProperties = [],
        data: Data = Data(),
        error: CharacteristicStringValueFailure? = .init(description: "TEST")
    ) -> Self {
        .init(properties: properties, data: data, error: error)
    }
    
    
    public static func makeSuccessfulStub(
        properties: CBCharacteristicProperties = [.read, .write],
        data: Data = Data()
    ) -> Self {
        .init(properties: properties, data: data, error: nil)
    }
}
