import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs
import ModelFoundation


public struct DescriptorModelFailure: Error, CustomStringConvertible {
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


public struct DescriptorModelState {
    public let uuid: CBUUID
    public let name: String?
    public var value: Result<Any?, DescriptorModelFailure>

    
    public init(uuid: CBUUID, name: String?, value: Result<Any?, DescriptorModelFailure>) {
        self.uuid = uuid
        self.name = name
        self.value = value
    }
    
    
    public static func initialState(fromDescriptorUUID cbuuid: CBUUID) -> Self {
        DescriptorModelState(
            uuid: cbuuid,
            name: DescriptorCatalog.from(cbuuid: cbuuid)?.name,
            value: .success(nil)
        )
    }
}


extension DescriptorModelState: CustomStringConvertible {
    public var description: String {
        let valueDescription: String
        switch value {
        case .success(let value):
            valueDescription = ".success(\(value ?? "nil"))"
        case .failure(let error):
            valueDescription = ".failure(\(error.description))"
        }
        return "DescriptorModelState(value: \(valueDescription), uuid: \(uuid.uuidString), name: \(name ?? "nil"))"
    }
}


extension DescriptorModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        let valueDescription: String
        switch value {
        case .success(let value):
            valueDescription = ".success(\(value == nil ? "nil" : "value"))"
        case .failure(let error):
            valueDescription = ".failure(\(error.description))"
        }
        return "DescriptorModelState(value: \(valueDescription), uuid: \(uuid.uuidString), name: \(name ?? "nil"))"
    }
}


public protocol DescriptorModelProtocol: StateMachineProtocol<DescriptorModelState>, Identifiable<CBUUID>, CustomStringConvertible {
    func read()
    func write(value: Data)
}


extension DescriptorModelProtocol {
    nonisolated public func eraseToAny() -> AnyDescriptorModel {
        AnyDescriptorModel(self)
    }
}


public actor AnyDescriptorModel: DescriptorModelProtocol {
    nonisolated public var state: DescriptorModelState { base.state }
    
    nonisolated public var id: CBUUID { base.id }
    nonisolated public var description: String { base.description }

    private let base: any DescriptorModelProtocol

    public init(_ base: any DescriptorModelProtocol) {
        self.base = base
    }
    
    nonisolated public var stateDidChange: AnyPublisher<State, Never> {
        base.stateDidChange
    }
    
    public func read() {
        Task { await base.read() }
    }
    
    public func write(value: Data) {
        Task { await base.write(value: value) }
    }
}


public actor DescriptorModel: DescriptorModelProtocol {
    private let descriptor: any DescriptorProtocol
    private let peripheral: any PeripheralProtocol
    nonisolated public let id: CBUUID
    
    nonisolated public var state: DescriptorModelState { stateDidChangeSubject.projected }
    nonisolated private let stateDidChangeSubject: ProjectedValueSubject<DescriptorModelState, Never>
    nonisolated public let stateDidChange: AnyPublisher<DescriptorModelState, Never>

    private var cancellables = Set<AnyCancellable>()
    
    public init(
        startsWith initialState: DescriptorModelState,
        representing descriptor: any DescriptorProtocol,
        onPeripheral peripheral: any PeripheralProtocol
   ) {
       self.descriptor = descriptor
       self.peripheral = peripheral
       self.id = descriptor.uuid
       
       let stateDidChangeSubject = ProjectedValueSubject<DescriptorModelState, Never>(initialState)
       self.stateDidChangeSubject = stateDidChangeSubject
       self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
       
       var mutableCancellables = Set<AnyCancellable>()
       
       peripheral.didUpdateValueForDescriptor
           .sink { [weak self] descriptor, error in
               guard let self = self else { return }
               Task {
                   await self.stateDidChangeSubject.change { prev in
                       var new = prev
                       if let error {
                           new.value = .failure(.init(wrapping: error))
                       } else {
                           new.value = .success(descriptor.value)
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
    
    
    public func read() {
        peripheral.readValue(for: descriptor)
    }
    
    
    public func write(value: Data) {
        peripheral.writeValue(value, for: descriptor)
    }
}


extension DescriptorModel: CustomStringConvertible {
    nonisolated public var description: String { state.description }
}
