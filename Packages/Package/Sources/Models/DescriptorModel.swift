import Combine
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs


public struct DescriptorModelFailure: Error {
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
        return "DescriptorModelState(value: \(valueDescription), uuid: \(uuid), name: \(name ?? "nil"))"
    }
}


public protocol DescriptorModelProtocol: Identifiable {
    var uuid: CBUUID { get }
    var state: DescriptorModelState { get set }
    var stateDidUpdate: AnyPublisher<DescriptorModelState, Never> { get }
    func refresh()
}


public class DescriptorModel: DescriptorModelProtocol {
    private let peripheral: any PeripheralProtocol
    private let descriptor: any DescriptorProtocol
    
    public var uuid: CBUUID { descriptor.uuid }
    
    public var state: DescriptorModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    
    private let stateDidUpdateSubject: CurrentValueSubject<DescriptorModelState, Never>
    public let stateDidUpdate: AnyPublisher<DescriptorModelState, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    
    init(
        startsWith initialState: DescriptorModelState,
        peripheral: any PeripheralProtocol,
        descriptor: any DescriptorProtocol
    ) {
        self.peripheral = peripheral
        self.descriptor = descriptor
        
        let stateDidUpdateSubject = CurrentValueSubject<DescriptorModelState, Never>(initialState)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
        self.peripheral.didUpdateValueForDescriptor
            .sink { [weak self] resp in
                guard let self else { return }
                guard self.descriptor.uuid == resp.descriptor.uuid else { return }
                
                if let value = resp.descriptor.value {
                    self.state.value = .success(value)
                } else if let error = resp.error {
                    self.state.value = .failure(DescriptorModelFailure(wrapping: error))
                } else {
                    self.state.value = .failure(DescriptorModelFailure(description: "Unknown error"))
                }
            }
            .store(in: &cancellables)
    }
    
    
    public func refresh() {
        self.peripheral.readValue(for: self.descriptor)
    }
}


extension DescriptorModel: Identifiable {
    public var id: Data { state.uuid.data }
}
