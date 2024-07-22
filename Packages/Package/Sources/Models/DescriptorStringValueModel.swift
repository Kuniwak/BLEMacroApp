import Combine
import CoreBluetooth
import CoreBluetoothTestable
import ModelFoundation
import BLEInternal


public struct DescriptorStringValueFailure: Error, Equatable, Sendable, CustomStringConvertible {
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


public protocol DescriptorStringValueModelProtocol: StateMachineProtocol<DescriptorValueModelState> {
    nonisolated func read()
    nonisolated func write()
    nonisolated func updateHexString(with string: String)
}


extension DescriptorStringValueModelProtocol {
    nonisolated public func eraseToAny() -> AnyDescriptorStringValueModel {
        AnyDescriptorStringValueModel(self)
    }
}


public final actor AnyDescriptorStringValueModel: DescriptorStringValueModelProtocol {
    private let base: any DescriptorStringValueModelProtocol
    
    nonisolated public var state: DescriptorValueModelState { base.state }
    nonisolated public var stateDidChange: AnyPublisher<DescriptorValueModelState, Never> { base.stateDidChange }
    
    
    public init(_ base: any DescriptorStringValueModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func read() {
        base.read()
    }
    
    
    nonisolated public func write() {
        base.write()
    }
    
    
    nonisolated public func updateHexString(with string: String) {
        base.updateHexString(with: string)
    }
}


public final actor DescriptorStringValueModel: DescriptorStringValueModelProtocol {
    nonisolated public var state: DescriptorValueModelState {
        switch hexDataModel.state {
        case .failure(let error):
            return .init(
                value: descriptorModel.state.value,
                error: .init(wrapping: error),
                canWrite: descriptorModel.state.canWrite
            )
        case .success:
            return .init(
                value: descriptorModel.state.value,
                error: nil,
                canWrite: descriptorModel.state.canWrite
            )
        }
    }
    nonisolated public let stateDidChange: AnyPublisher<DescriptorValueModelState, Never>
    nonisolated private let descriptorModel: any DescriptorValueModelProtocol
    nonisolated private let hexDataModel: any HexDataModelProtocol
    
    
    public init(
        startsWith initialState: String,
        representing descriptor: any DescriptorProtocol,
        onPeripheral peripheral: any PeripheralProtocol
    ) {
        let result: Result<Data, HexDataModelFailure>
        switch HexEncoding.decode(hexString: initialState) {
        case .success((let d, _)):
            result = .success(d)
        case .failure(let e):
            result = .failure(.init(wrapping: e))
        }
        
        self.descriptorModel = DescriptorValueModel(
            startsWith: .initialState(uuid: descriptor.uuid, value: nil),
            representing: descriptor,
            onPeripheral: peripheral
        )
        self.hexDataModel = HexDataModel(startsWith: result)
        
        self.stateDidChange = Publishers
            .CombineLatest(
                descriptorModel.stateDidChange,
                hexDataModel.stateDidChange
            )
            .map { (descriptor, hexData) in
                switch hexData {
                case .failure(let error):
                    return .init(
                        value: descriptor.value,
                        error: .init(wrapping: error),
                        canWrite: descriptor.canWrite
                    )
                case .success:
                    return .init(
                        value: descriptor.value,
                        error: nil,
                        canWrite: descriptor.canWrite
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    
    nonisolated public func read() {
        descriptorModel.read()
    }
    
    
    nonisolated public func write() {
        switch hexDataModel.state {
        case .failure:
            return
            
        case .success(let data):
            descriptorModel.write(value: data)
        }
    }
    
    
    nonisolated public func updateHexString(with string: String) {
        hexDataModel.updateHexString(with: string)
    }
}
