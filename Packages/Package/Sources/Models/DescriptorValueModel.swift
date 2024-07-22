import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothTestable
import BLEInternal
import Catalogs
import ModelFoundation
import MirrorDiffKit


public enum DescriptorValue {
    case data(Data)
    case string(String)
    case number(NSNumber)
    case uint64(UInt64)
    case unknown(Any)
    
    
    public static func from(uuid: CBUUID, value: Any) -> Result<Self, DescriptorValueModelFailure> {
        switch uuid.uuidString {
        case CBUUIDCharacteristicFormatString:
            guard let data = value as? Data else {
                return .failure(DescriptorValueModelFailure(description: "Invalid data"))
            }
            return .success(.data(data))
        case CBUUIDCharacteristicUserDescriptionString:
            guard let string = value as? String else {
                return .failure(DescriptorValueModelFailure(description: "Invalid string"))
            }
            return .success(.string(string))
        case CBUUIDCharacteristicExtendedPropertiesString:
            guard let number = value as? NSNumber else {
                return .failure(DescriptorValueModelFailure(description: "Invalid number"))
            }
            return .success(.number(number))
        case CBUUIDClientCharacteristicConfigurationString:
            guard let number = value as? NSNumber else {
                return .failure(DescriptorValueModelFailure(description: "Invalid number"))
            }
            return .success(.number(number))
        case CBUUIDServerCharacteristicConfigurationString:
            guard let number = value as? NSNumber else {
                return .failure(DescriptorValueModelFailure(description: "Invalid number"))
            }
            return .success(.number(number))
        case CBUUIDCharacteristicAggregateFormatString:
            guard let string = value as? String else {
                return .failure(DescriptorValueModelFailure(description: "Invalid string"))
            }
            return .success(.string(string))
        case CBUUIDL2CAPPSMCharacteristicString:
            guard let uint64 = value as? UInt64 else {
                return .failure(DescriptorValueModelFailure(description: "Invalid UInt64"))
            }
            return .success(.uint64(uint64))
        default:
            return .success(.unknown(value))
        }
    }
}


extension DescriptorValue: Equatable {
    public static func == (lhs: DescriptorValue, rhs: DescriptorValue) -> Bool {
        switch (lhs, rhs) {
        case (.data(let l), .data(let r)):
            return l == r
        case (.string(let l), .string(let r)):
            return l == r
        case (.number(let l), .number(let r)):
            return l == r
        case (.uint64(let l), .uint64(let r)):
            return l == r
        case (.unknown(let l), .unknown(let r)):
            return l =~ r
        default:
            return false
        }
    }
}


extension DescriptorValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .data(let data):
            return HexEncoding.upper.encode(data: data)
        case .string(let string):
            return string
        case .number(let number):
            return number.description
        case .uint64(let uint64):
            return uint64.description
        case .unknown(let value):
            return "\(value)"
        }
    }
}


extension DescriptorValue: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .data:
            return "Data"
        case .string:
            return "String"
        case .number:
            return "NSNumber"
        case .uint64:
            return "UInt64"
        case .unknown(let value):
            return "unknown(\(type(of: value)))"
        }
    }
}


public struct DescriptorValueModelFailure: Error, CustomStringConvertible, Equatable {
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


public struct DescriptorValueModelState: Equatable {
    public var value: DescriptorValue?
    public var error: DescriptorValueModelFailure?
    public var canWrite: Bool

    
    public init(value: DescriptorValue?, error: DescriptorValueModelFailure?, canWrite: Bool) {
        self.value = value
        self.error = error
        self.canWrite = canWrite
    }
    
    
    public static func initialState(uuid: CBUUID, value: DescriptorValue?) -> Self {
        DescriptorValueModelState(
            value: value,
            error: nil,
            // NOTE: > You can’t use this method to write the value of a client configuration descriptor
            //       > (represented by the CBUUIDClientCharacteristicConfigurationString constant),
            //       > which describes the configuration of notification or indications for a characteristic’s value.
            //       > If you want to manage notifications or indications for a characteristic’s value,
            //       > you must use the setNotifyValue(_:for:) method instead.
            // SEE: https://developer.apple.com/documentation/corebluetooth/cbperipheral/writevalue(_:for:)
            canWrite: uuid.uuidString != CBUUIDClientCharacteristicConfigurationString
        )
    }
}


extension DescriptorValueModelState: CustomStringConvertible {
    public var description: String {
        return "(value: \(value?.description ?? "nil"), error: \(error?.description ?? "nil")"
    }
}


extension DescriptorValueModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "(value: \(value?.debugDescription ?? "nil"), error: \(error == nil ? ".none" : ".some")"
    }
}


public protocol DescriptorValueModelProtocol: StateMachineProtocol, Identifiable<CBUUID>, CustomStringConvertible where State == DescriptorValueModelState {
    nonisolated func read()
    nonisolated func write(value: Data)
}


extension DescriptorValueModelProtocol {
    nonisolated public func eraseToAny() -> AnyDescriptorValueModel {
        AnyDescriptorValueModel(self)
    }
}


public final actor AnyDescriptorValueModel: DescriptorValueModelProtocol {
    nonisolated public var state: DescriptorValueModelState { base.state }
    
    nonisolated public var id: CBUUID { base.id }
    nonisolated public var description: String { base.description }

    private let base: any DescriptorValueModelProtocol

    public init(_ base: any DescriptorValueModelProtocol) {
        self.base = base
    }
    
    nonisolated public var stateDidChange: AnyPublisher<State, Never> {
        base.stateDidChange
    }
    
    nonisolated public func read() {
        base.read()
    }
    
    nonisolated public func write(value: Data) {
        base.write(value: value)
    }
}


extension AnyDescriptorValueModel: Equatable {
    public static func == (lhs: AnyDescriptorValueModel, rhs: AnyDescriptorValueModel) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}


public final actor DescriptorValueModel: DescriptorValueModelProtocol {
    private let descriptor: any DescriptorProtocol
    private let peripheral: any PeripheralProtocol
    nonisolated public let id: CBUUID
    
    nonisolated public var state: DescriptorValueModelState { stateDidChangeSubject.value }
    nonisolated private let stateDidChangeSubject: ConcurrentValueSubject<DescriptorValueModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<DescriptorValueModelState, Never>

    private var cancellables = Set<AnyCancellable>()
    
    public init(
        startsWith initialState: DescriptorValueModelState,
        representing descriptor: any DescriptorProtocol,
        onPeripheral peripheral: any PeripheralProtocol
   ) {
       self.descriptor = descriptor
       self.peripheral = peripheral
       self.id = descriptor.uuid
       
       let stateDidChangeSubject = ConcurrentValueSubject<DescriptorValueModelState, Never>(initialState)
       self.stateDidChangeSubject = stateDidChangeSubject
       self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
       
       var mutableCancellables = Set<AnyCancellable>()
       
       peripheral.didUpdateValueForDescriptor
           .sink { [weak self] descriptor, error in
               guard let self = self else { return }
               Task {
                   await self.stateDidChangeSubject.change { prev in
                       var new = prev
                       if let value = descriptor.value {
                           switch DescriptorValue.from(uuid: descriptor.uuid, value: value) {
                           case .success(let value):
                               new.value = value
                               new.error = nil
                           case .failure(let error):
                               new.value = nil
                               new.error = error
                           }
                       } else {
                           new.value = nil
                           new.error = error.map(DescriptorValueModelFailure.init(wrapping:))
                       }
                       return new
                   }
               }
           }
           .store(in: &mutableCancellables)
       
       let cancellables = mutableCancellables
       Task { await self.store(cancellables: cancellables) }
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables.formUnion(cancellables)
    }
    
    
    nonisolated public func read() {
        Task {
            await peripheral.readValue(for: descriptor)
        }
    }
    
    
    nonisolated public func write(value: Data) {
        Task {
            if state.canWrite {
                await peripheral.writeValue(value, for: descriptor)
            }
        }
    }
}


extension DescriptorValueModel: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}
