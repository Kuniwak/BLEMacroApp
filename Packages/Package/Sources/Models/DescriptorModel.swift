import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs


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


public protocol DescriptorModelProtocol: StateMachine, Identifiable<CBUUID> where State == DescriptorModelState {
    var state: DescriptorModelState { get async }
    
    func read()
    func write(value: Data)
}


extension DescriptorModelProtocol {
    nonisolated public func eraseToAny() -> AnyDescriptorModel {
        AnyDescriptorModel(self)
    }
}


public actor AnyDescriptorModel: DescriptorModelProtocol {
    public var state: DescriptorModelState {
        get async { await base.state }
    }
    
    nonisolated public var id: CBUUID { base.id }
    nonisolated public var initialState: DescriptorModelState { base.initialState }

    private let base: any DescriptorModelProtocol

    public init(_ base: any DescriptorModelProtocol) {
        self.base = base
    }
    
    nonisolated public var stateDidUpdate: AnyPublisher<State, Never> {
        base.stateDidUpdate
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
    
    public var state: DescriptorModelState {
        get async { await stateDidUpdateSubject.value }
    }
    
    nonisolated public let initialState: DescriptorModelState
    
    private let stateDidUpdateSubject: ConcurrentValueSubject<DescriptorModelState, Never>
    nonisolated public let stateDidUpdate: AnyPublisher<DescriptorModelState, Never>

    private var cancellables = Set<AnyCancellable>()
    
    public init(
        startsWith initialState: DescriptorModelState,
        representing descriptor: any DescriptorProtocol,
        onPeripheral peripheral: any PeripheralProtocol
   ) {
       self.initialState = initialState
       
       self.descriptor = descriptor
       self.peripheral = peripheral
       self.id = descriptor.uuid
       
       let stateDidUpdateSubject = ConcurrentValueSubject<DescriptorModelState, Never>(initialState)
       self.stateDidUpdateSubject = stateDidUpdateSubject
       self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
       
       var mutableCancellables = Set<AnyCancellable>()
       
       peripheral.didUpdateValueForDescriptor
           .sink { [weak self] descriptor, error in
               guard let self = self else { return }
               Task {
                   await self.stateDidUpdateSubject.change { prev in
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
