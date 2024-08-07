import Foundation
import Combine
import CoreBluetooth
import CoreBluetoothTestable
import ConcurrentCombine
import ModelFoundation


public struct CharacteristicValueModelFailure: Error, Equatable {
    public let description: String
    
    
    public init(description: String) {
        self.description = description
    }
    
    
    public init(wrapping error: any Error) {
        self.description = "\(error)"
    }
}


public struct CharacteristicValueState: Equatable {
    public let properties: CBCharacteristicProperties
    public let value: Data
    public let isNotifying: Bool
    public let error: CharacteristicValueModelFailure?
    
    
    public init(
        properties: CBCharacteristicProperties,
        value: Data,
        isNotifying: Bool,
        error: CharacteristicValueModelFailure?
    ) {
        self.properties = properties
        self.value = value
        self.isNotifying = isNotifying
        self.error = error
    }
    
    
    public static func initialState(properties: CBCharacteristicProperties, isNotifying: Bool) -> CharacteristicValueState {
        return CharacteristicValueState(properties: properties, value: Data(), isNotifying: isNotifying, error: nil)
    }
}


extension CharacteristicValueState: CustomStringConvertible {
    public var description: String {
        return "(properties: \(properties), value: \(value), isNotifying: \(isNotifying), error: \(error?.description ?? "nil"))"
    }
}


extension CharacteristicValueState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "CharacteristicValueState(properties: \(properties), value: \(value), isNotifying: \(isNotifying), error: \(error == nil ? ".none" : ".some"))"
    }
}


public protocol CharacteristicValueModelProtocol: StateMachineProtocol<CharacteristicValueState> {
    nonisolated func read()
    nonisolated func write(value: Data, type: CBCharacteristicWriteType)
    nonisolated func setNotify(_ enabled: Bool)
}


extension CharacteristicValueModelProtocol {
    nonisolated public func eraseToAny() -> AnyCharacteristicValueModel {
        return AnyCharacteristicValueModel(self)
    }
}


public final actor AnyCharacteristicValueModel: CharacteristicValueModelProtocol {
    nonisolated public let model: any CharacteristicValueModelProtocol
    nonisolated public var state: CharacteristicValueState { model.state }
    nonisolated public var stateDidChange: AnyPublisher<CharacteristicValueState, Never> { model.stateDidChange }
    
    
    public init(_ model: any CharacteristicValueModelProtocol) {
        self.model = model
    }
    
    
    nonisolated public func read() {
        model.read()
    }
    
    
    nonisolated public func write(value: Data, type: CBCharacteristicWriteType) {
        model.write(value: value, type: type)
    }
    
    
    nonisolated public func setNotify(_ enabled: Bool) {
        model.setNotify(enabled)
    }
}


public final actor CharacteristicValueModel: CharacteristicValueModelProtocol {
    nonisolated public var state: CharacteristicValueState { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<CharacteristicValueState, Never>
    nonisolated private let stateDidChangeSubject: ConcurrentValueSubject<CharacteristicValueState, Never>
    private let peripheral: any PeripheralProtocol
    private let characteristic: any CharacteristicProtocol
    private var cancellables = Set<AnyCancellable>()
    nonisolated public let uuid: CBUUID
    
    
    public init(
        startsWith initialState: CharacteristicValueState,
        operatingOn peripheral: any PeripheralProtocol,
        representing characteristic: any CharacteristicProtocol
    ) {
        let stateDidChangeSubject = ConcurrentValueSubject<CharacteristicValueState, Never>(initialState)
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
        self.stateDidChangeSubject = stateDidChangeSubject
        
        self.uuid = characteristic.uuid
        
        self.peripheral = peripheral
        self.characteristic = characteristic
        
        var mutableCancellables = Set<AnyCancellable>()
        
        peripheral.didUpdateValueForCharacteristic
            .sink { [weak self] (characteristic, error) in
                guard let self, characteristic.uuid == self.uuid else { return }
                Task {
                    await self.stateDidChangeSubject.change { _ in
                        return .init(
                            properties: characteristic.properties,
                            value: characteristic.value ?? Data(),
                            isNotifying: characteristic.isNotifying,
                            error: error.map(CharacteristicValueModelFailure.init(wrapping:))
                        )
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        peripheral.didWriteValueForCharacteristic
            .sink { [weak self] (characteristic, error) in
                guard let self, characteristic.uuid == self.uuid else { return }
                Task {
                    await self.stateDidChangeSubject.change { _ in
                        return .init(
                            properties: characteristic.properties,
                            value: characteristic.value ?? Data(),
                            isNotifying: characteristic.isNotifying,
                            error: error.map(CharacteristicValueModelFailure.init(wrapping:))
                        )
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        peripheral.didUpdateNotificationStateForCharacteristic
            .sink { [weak self] (characteristic, error) in
                guard let self, characteristic.uuid == self.uuid else { return }
                Task {
                    await self.stateDidChangeSubject.change { _ in
                        return .init(
                            properties: characteristic.properties,
                            value: characteristic.value ?? Data(),
                            isNotifying: characteristic.isNotifying,
                            error: error.map(CharacteristicValueModelFailure.init(wrapping:))
                        )
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        let cancellables = mutableCancellables
        Task { await appendCancellables(cancellables) }
    }
    
    
    private func appendCancellables(_ cancellables: Set<AnyCancellable>) {
        self.cancellables.formUnion(cancellables)
    }
    
    
    nonisolated public func read() {
        Task {
            await stateDidChangeSubject.change { prev in
                if state.properties.contains(.read) {
                    Task { await peripheral.readValue(for: characteristic) }
                    return prev
                } else {
                    return .init(
                        properties: prev.properties,
                        value: prev.value,
                        isNotifying: prev.isNotifying,
                        error: .init(description: "Not readable")
                    )
                }
            }
        }
    }
    
    
    nonisolated public func write(value: Data, type: CBCharacteristicWriteType) {
        Task {
            await stateDidChangeSubject.change { prev in
                switch type {
                case .withResponse:
                    if state.properties.contains(.write) {
                        Task { await peripheral.writeValue(value, for: characteristic, type: type) }
                        return prev
                    } else {
                        return .init(
                            properties: prev.properties,
                            value: prev.value,
                            isNotifying: prev.isNotifying,
                            error: .init(description: "Not writable with response")
                        )
                    }
                case .withoutResponse:
                    if state.properties.contains(.writeWithoutResponse) {
                        Task { await peripheral.writeValue(value, for: characteristic, type: type) }
                        return prev
                    } else {
                        return .init(
                            properties: prev.properties,
                            value: prev.value,
                            isNotifying: prev.isNotifying,
                            error: .init(description: "Not writable without response")
                        )
                    }
                default:
                    return .init(
                        properties: prev.properties,
                        value: prev.value,
                        isNotifying: prev.isNotifying,
                        error: .init(description: "Unknown write type: \(type)")
                    )
                }
            }
        }
    }
    
    
    nonisolated public func setNotify(_ enabled: Bool) {
        Task {
            await stateDidChangeSubject.change { prev in
                if state.properties.contains(.notify) {
                    Task { await peripheral.setNotifyValue(enabled, for: characteristic) }
                    return prev
                } else {
                    return .init(
                        properties: prev.properties,
                        value: prev.value,
                        isNotifying: prev.isNotifying,
                        error: .init(description: "Not subscribable")
                    )
                }
            }
        }
    }
}
