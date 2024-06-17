import Combine
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
    public var value: Result<Any?, DescriptorModelFailure>
    public let uuid: CBUUID
    public let name: String?
    
    
    public init(value: Result<Any?, DescriptorModelFailure>, uuid: CBUUID, name: String?) {
        self.value = value
        self.uuid = uuid
        self.name = name
    }
    
    
    public static func initialState(fromDescriptorUUID cbuuid: CBUUID) -> Self {
        DescriptorModelState(
            value: .success(nil),
            uuid: cbuuid,
            name: DescriptorCatalog.from(cbuuid: cbuuid)?.name
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


public protocol DescriptorModelProtocol: Actor, Identifiable<CBUUID>, ObservableObject where ObjectWillChangePublisher == AnyPublisher<Any, Never>{
    nonisolated var stateDidUpdate: AnyPublisher<DescriptorModelState, Never> { get }
    
    func read()
    func write(value: Data)
}


extension DescriptorModelProtocol {
    nonisolated public func eraseToAny() -> AnyDescriptorModel {
        AnyDescriptorModel(self)
    }
}


public actor AnyDescriptorModel: DescriptorModelProtocol {
    private let base: any DescriptorModelProtocol
    
    public init(_ base: any DescriptorModelProtocol) {
        self.base = base
    }
    
    nonisolated public var stateDidUpdate: AnyPublisher<DescriptorModelState, Never> {
        base.stateDidUpdate
    }
    
    nonisolated public var objectWillChange: AnyPublisher<Any, Never> {
        base.objectWillChange
    }
    
    nonisolated public var id: CBUUID { base.id }
    
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
    
    private let stateDidUpdateSubject: ConcurrentValueSubject<DescriptorModelState, Never>
    nonisolated public let stateDidUpdate: AnyPublisher<DescriptorModelState, Never>
    nonisolated public let objectWillChange: AnyPublisher<Any, Never>

    private var cancellables = Set<AnyCancellable>()
    
    public init(
        startsWith initialState: DescriptorModelState,
        descriptor: any DescriptorProtocol,
        peripheral: any PeripheralProtocol
   ) {
       self.descriptor = descriptor
       self.peripheral = peripheral
       self.id = descriptor.uuid
       
       let stateDidUpdateSubject = ConcurrentValueSubject<DescriptorModelState, Never>(initialState)
       self.stateDidUpdateSubject = stateDidUpdateSubject
       self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
       self.objectWillChange = stateDidUpdateSubject.map { _ in () }.eraseToAnyPublisher()
       
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
