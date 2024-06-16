import Combine
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs


public struct CharacteristicModelFailure: Error, CustomStringConvertible {
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


public enum DescriptorDiscoveryState {
    case discovering
    case discovered([any DescriptorModelProtocol]?)
    case discoverFailed(CharacteristicModelFailure)
    
    
    public var descriptors: [any DescriptorModelProtocol] {
        switch self {
        case .discovered(.some(let descriptors)):
            return descriptors
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


extension DescriptorDiscoveryState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .discovering:
            return ".discovering"
        case .discovered(.some(let descriptors)):
            return ".discovered([\(descriptors.map(\.state.description).joined(separator: ", "))])"
        case .discovered(nil):
            return ".discovered(nil)"
        case .discoverFailed(let error):
            return ".discoverFailed(\(error.description))"
        }
    }
}


public struct CharacteristicModelState {
    public var discoveryState: DescriptorDiscoveryState
    public let uuid: CBUUID
    public let name: String?
    
    
    public init(discoveryState: DescriptorDiscoveryState, uuid: CBUUID, name: String?) {
        self.discoveryState = discoveryState
        self.uuid = uuid
        self.name = name
    }
    
    
    public static func initialState(fromCharacteristicUUID cbuuid: CBUUID) -> Self {
        CharacteristicModelState(
            discoveryState: .discovered(nil),
            uuid: cbuuid,
            name: CharacteristicCatalog.from(cbuuid: cbuuid)?.name
        )
    }
}


extension CharacteristicModelState: CustomStringConvertible {
    public var description: String {
        return "CharacteristicModelState(discoveryState: \(discoveryState.description), uuid: \(uuid), name: \(name ?? "nil"))"
    }
}


public protocol CharacteristicModelProtocol: Identifiable {
    var uuid: CBUUID { get }
    var state: CharacteristicModelState { get set }
    var stateDidUpdate: AnyPublisher<CharacteristicModelState, Never> { get }
    func discoverDescriptors()
    func refresh()
}


public class CharacteristicModel: CharacteristicModelProtocol {
    private let peripheral: any PeripheralProtocol
    private let characteristic: any CharacteristicProtocol
    
    public var uuid: CBUUID { characteristic.uuid }
    
    public var state: CharacteristicModelState {
        get {
            stateDidUpdateSubject.value
        }
        set {
            stateDidUpdateSubject.value = newValue
        }
    }
    
    private let stateDidUpdateSubject: CurrentValueSubject<CharacteristicModelState, Never>
    public let stateDidUpdate: AnyPublisher<CharacteristicModelState, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(
        startsWith initialState: CharacteristicModelState,
        peripheral: any PeripheralProtocol,
        characteristic: any CharacteristicProtocol
    ) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        
        let stateDidUpdateSubject = CurrentValueSubject<CharacteristicModelState, Never>(initialState)
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
        self.peripheral.didDiscoverDescriptorsForCharacteristic
            .sink { [weak self] resp in
                guard let self else { return }
                guard resp.characteristic.uuid == self.characteristic.uuid else { return }
                
                if let descriptors = resp.descriptors {
                    let descriptors = descriptors.map {
                        DescriptorModel(
                            startsWith: .initialState(fromDescriptorUUID: $0.uuid),
                            peripheral: peripheral,
                            descriptor: $0
                        )
                    }
                    self.state.discoveryState = .discovered(descriptors)
                } else {
                    self.state.discoveryState = .discoverFailed(.init(wrapping: resp.error))
                }
            }
            .store(in: &cancellables)
    }
    
    
    public func discoverDescriptors() {
        guard !state.discoveryState.isDiscovering else { return }
        state.discoveryState = .discovering
        peripheral.discoverDescriptors(for: characteristic)
    }
    
    
    public func refresh() {
        guard !state.discoveryState.isDiscovering else { return }
        state = .initialState(fromCharacteristicUUID: characteristic.uuid)
        discoverDescriptors()
    }
}


extension CharacteristicModel: Identifiable {
    public var id: Data { state.uuid.data }
}
