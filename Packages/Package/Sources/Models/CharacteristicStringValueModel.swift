import Combine
import CoreBluetooth
import CoreBluetoothTestable
import ModelFoundation
import BLEInternal


public struct CharacteristicStringValueFailure: Error, Equatable, Sendable, CustomStringConvertible {
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


public struct CharacteristicStringValueState: Equatable, Sendable {
    public let properties: CBCharacteristicProperties
    public let data: Data
    public let error: CharacteristicStringValueFailure?
    
    
    public init(
        properties: CBCharacteristicProperties,
        data: Data,
        error: CharacteristicStringValueFailure?
    ) {
        self.properties = properties
        self.data = data
        self.error = error
    }
}


extension CharacteristicStringValueState: CustomStringConvertible {
    public var description: String {
        "CharacteristicStringValueState(properties: \(properties), data: \(data), error: \(error?.description ?? "nil"))"
    }
}


public protocol CharacteristicStringValueModelProtocol: StateMachineProtocol<CharacteristicStringValueState> {
    nonisolated func read()
    nonisolated func write(type: CBCharacteristicWriteType)
    nonisolated func update(byString string: String)
    nonisolated func setNotify(_ enabled: Bool)
}


extension CharacteristicStringValueModelProtocol {
    nonisolated public func eraseToAny() -> AnyCharacteristicStringValueModel {
        AnyCharacteristicStringValueModel(self)
    }
}


public final actor AnyCharacteristicStringValueModel: CharacteristicStringValueModelProtocol {
    private let base: any CharacteristicStringValueModelProtocol
    
    nonisolated public var state: CharacteristicStringValueState { base.state }
    nonisolated public var stateDidChange: AnyPublisher<CharacteristicStringValueState, Never> { base.stateDidChange }
    
    
    public init(_ base: any CharacteristicStringValueModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func read() {
        base.read()
    }
    
    
    nonisolated public func write(type: CBCharacteristicWriteType) {
        base.write(type: type)
    }
    
    
    nonisolated public func update(byString string: String) {
        base.update(byString: string)
    }
    
    
    nonisolated public func setNotify(_ enabled: Bool) {
        base.setNotify(enabled)
    }
}


public final actor CharacteristicStringValueModel: CharacteristicStringValueModelProtocol {
    nonisolated public var state: CharacteristicStringValueState {
        switch hexDataModel.state {
        case .failure(let error):
            return .init(
                properties: characterisitcModel.state.properties,
                data: characterisitcModel.state.value,
                error: .init(wrapping: error)
            )
        case .success:
            return .init(
                properties: characterisitcModel.state.properties,
                data: characterisitcModel.state.value,
                error: .init(wrapping: characterisitcModel.state.error)
            )
        }
    }
    nonisolated public let stateDidChange: AnyPublisher<CharacteristicStringValueState, Never>
    nonisolated private let characterisitcModel: any CharacteristicValueModelProtocol
    nonisolated private let hexDataModel: any HexDataModelProtocol
    
    
    public init(
        startsWith initialState: String,
        operatingOn peripheral: any PeripheralProtocol,
        representing characteristic: any CharacteristicProtocol
    ) {
        let data: Data
        let result: Result<Data, HexDataModelFailure>
        switch HexEncoding.decode(hexString: initialState) {
        case .success((let d, _)):
            data = d
            result = .success(d)
        case .failure(let e):
            data = Data()
            result = .failure(.init(wrapping: e))
        }
        
        self.characterisitcModel = CharacteristicValueModel(
            startsWith: .init(
                properties: characteristic.properties,
                value: data,
                error: nil
            ),
            operatingOn: peripheral,
            representing: characteristic
        )
        self.hexDataModel = HexDataModel(startsWith: result)
        
        self.stateDidChange = Publishers
            .CombineLatest(
                characterisitcModel.stateDidChange,
                hexDataModel.stateDidChange
            )
            .map { (characteristic, hexData) in
                switch hexData {
                case .failure(let error):
                    return .init(
                        properties: characteristic.properties,
                        data: characteristic.value,
                        error: .init(wrapping: error)
                    )
                case .success:
                    return .init(
                        properties: characteristic.properties,
                        data: characteristic.value,
                        error: .init(wrapping: characteristic.error)
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    
    nonisolated public func read() {
        characterisitcModel.read()
    }
    
    
    nonisolated public func write(type: CBCharacteristicWriteType) {
        switch hexDataModel.state {
        case .failure:
            return
            
        case .success(let data):
            characterisitcModel.write(value: data, type: type)
        }
    }
    
    
    nonisolated public func update(byString string: String) {
        hexDataModel.update(byString: string)
    }
    
    
    nonisolated public func setNotify(_ enabled: Bool) {
        characterisitcModel.setNotify(enabled)
    }
}
