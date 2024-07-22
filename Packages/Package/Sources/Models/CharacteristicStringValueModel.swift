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


extension CBCharacteristicProperties {
    fileprivate var description: String {
        var components = [String]()
        if contains(.broadcast) { components.append("broadcast") }
        if contains(.read) { components.append("read") }
        if contains(.writeWithoutResponse) { components.append("writeWithoutResponse") }
        if contains(.write) { components.append("write") }
        if contains(.notify) { components.append("notify") }
        if contains(.indicate) { components.append("indicate") }
        if contains(.authenticatedSignedWrites) { components.append("authenticatedSignedWrites") }
        if contains(.extendedProperties) { components.append("extendedProperties") }
        if contains(.notifyEncryptionRequired) { components.append("notifyEncryptionRequired") }
        if contains(.indicateEncryptionRequired) { components.append("indicateEncryptionRequired") }
        return components.joined(separator: "/")
    }
}


extension CharacteristicStringValueState: CustomStringConvertible {
    public var description: String {
        "(properties: \(properties.description), data: \(data), error: \(error?.description ?? "nil"))"
    }
}


extension CharacteristicStringValueState: CustomDebugStringConvertible {
    public var debugDescription: String {
        "(properties: \(properties), data: \(data.count) bytes, error: \(error == nil ? ".none" : ".some"))"
    }
}


public protocol CharacteristicStringValueModelProtocol: StateMachineProtocol<CharacteristicStringValueState> {
    nonisolated func read()
    nonisolated func write(type: CBCharacteristicWriteType)
    nonisolated func updateHexString(with string: String)
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
    
    
    nonisolated public func updateHexString(with string: String) {
        base.updateHexString(with: string)
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
    
    
    nonisolated public func updateHexString(with string: String) {
        hexDataModel.updateHexString(with: string)
    }
    
    
    nonisolated public func setNotify(_ enabled: Bool) {
        characterisitcModel.setNotify(enabled)
    }
}
