import Combine
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs


public struct ServiceModelFailure: Error {
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


public enum CharacteristicDiscoveryState {
    case discovering
    case discovered([any CharacteristicModelProtocol]?)
    case discoverFailed(ServiceModelFailure)
    
    
    public var characteristics: [any CharacteristicModelProtocol] {
        switch self {
        case .discovered(.some(let characteristics)):
            return characteristics
        case .discovering, .discovered(nil), .discoverFailed:
            return []
        }
    }
    
    
    public var isDiscovering: Bool {
        switch self {
        case .discovering:
            return true
        case .discovered, .discoverFailed:
            return false
        }
    }
}



public struct ServiceModelState {
    public let discoveryState: CharacteristicDiscoveryState
    public let uuid: CBUUID
    public let name: String?
    
    
    public init(discoveryState: CharacteristicDiscoveryState, uuid: CBUUID, name: String?) {
        self.discoveryState = discoveryState
        self.uuid = uuid
        self.name = name
    }
    
    
    public static func initialState(fromServiceUUID uuid: CBUUID) -> Self {
        ServiceModelState(
            discoveryState: .discovered(nil),
            uuid: uuid,
            name: ServiceCatalog.from(cbuuid: uuid)?.name
        )
    }
}


public protocol ServiceModelProtocol: Identifiable {
    var uuid: CBUUID { get }
    var state: ServiceModelState { get set }
    var stateDidUpdate: AnyPublisher<ServiceModelState, Never> { get }
    func discoverCharacteristics()
    func refresh()
}


public class ServiceModel: ServiceModelProtocol {
    private let peripheral: any PeripheralProtocol
    private let service: any ServiceProtocol
    
    private let stateDidUpdateSubject: CurrentValueSubject<ServiceModelState, Never>
    public let stateDidUpdate: AnyPublisher<ServiceModelState, Never>
    
    public var uuid: CBUUID { service.uuid }
    
    public var state: ServiceModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(startsWith initialState: ServiceModelState, peripheral: any PeripheralProtocol, service: any ServiceProtocol) {
        self.peripheral = peripheral
        self.service = service
        
        let stateDidUpdateSubject = CurrentValueSubject<ServiceModelState, Never>(initialState)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
        self.peripheral.didDiscoverCharacteristicsForService
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.service.uuid == self.service.uuid else { return }
                
                if let characteristics = resp.characteristics {
                    let characteristics = characteristics.map {
                        CharacteristicModel(
                            startsWith: .initialState(fromCharacteristicUUID: $0.uuid),
                            peripheral: self.peripheral,
                            characteristic: $0
                        )
                    }
                    self.state = ServiceModelState(
                        discoveryState: .discovered(characteristics),
                        uuid: self.service.uuid,
                        name: self.state.name
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    
    public func discoverCharacteristics() {
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    
    public func refresh() {
        self.state = .initialState(fromServiceUUID: service.uuid)
        discoverCharacteristics()
    }
}


extension ServiceModel: Identifiable {
    public var id: Data { state.uuid.data }
}
