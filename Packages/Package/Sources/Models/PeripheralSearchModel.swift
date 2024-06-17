import Combine
import BLEInternal
import CoreBluetoothTestable


public struct PeripheralSearchModelState {
    public var discoveryState: PeripheralDiscoveryModelState
    public var searchQuery: String
    
    
    public init(discoveryState: PeripheralDiscoveryModelState, searchQuery: String) {
        self.discoveryState = discoveryState
        self.searchQuery = searchQuery
    }
    
    
    public static func initialState(searchQuery: String) -> Self {
        .init(
            discoveryState: .initialState(),
            searchQuery: searchQuery
        )
    }
    
    
    public static func from(discoveryState: PeripheralDiscoveryModelState, searchQuery: String) -> Self {
        switch discoveryState {
        case .idle, .ready, .discoveryFailed:
            return .init(discoveryState: discoveryState, searchQuery: searchQuery)
        case .discovering(let peripherals):
            return .init(discoveryState: .discovering(peripherals.filter(satisfy(searchQuery: searchQuery))), searchQuery: searchQuery)
        case .discovered(let peripherals):
            return .init(discoveryState: .discovered(peripherals.filter(satisfy(searchQuery: searchQuery))), searchQuery: searchQuery)
        }
    }
}


extension PeripheralSearchModelState: CustomStringConvertible {
    public var description: String {
        "PeripheralSearchModelState(discoveryState: \(discoveryState.description), searchQuery: \(searchQuery))"
    }
}


extension PeripheralSearchModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        "PeripheralSearchModelState(discoveryState: \(discoveryState.debugDescription), searchQuery: \(searchQuery))"
    }
}


public protocol PeripheralSearchModelProtocol: ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    var state: PeripheralSearchModelState { get }
    var stateDidUpdate: AnyPublisher<PeripheralSearchModelState, Never> { get }
    var searchQuery: CurrentValueSubject<String, Never> { get }
    func startScan()
    func stopScan()
}


extension PeripheralSearchModelProtocol {
    public func eraseToAny() -> AnyPeripheralSearchModel {
        AnyPeripheralSearchModel(self)
    }
}


public class AnyPeripheralSearchModel: PeripheralSearchModelProtocol {
    private let base: any PeripheralSearchModelProtocol
    
    public var state: PeripheralSearchModelState { base.state }
    public var stateDidUpdate: AnyPublisher<PeripheralSearchModelState, Never> { base.stateDidUpdate }
    
    public var searchQuery: CurrentValueSubject<String, Never> { base.searchQuery }
    public var objectWillChange: ObservableObjectPublisher { base.objectWillChange }
    
    public func startScan() {
        base.startScan()
    }
    
    public func stopScan() {
        base.stopScan()
    }
    
    
    public init(_ base: any PeripheralSearchModelProtocol) {
        self.base = base
    }
}


public class PeripheralSearchModel: PeripheralSearchModelProtocol {
    public var state: PeripheralSearchModelState {
        get {
            .from(discoveryState: discoveryModel.state, searchQuery: searchQuery.value)
        }
    }
    
    
    public let stateDidUpdate: AnyPublisher<PeripheralSearchModelState, Never>
    
    public let searchQuery: CurrentValueSubject<String, Never>
    
    public let objectWillChange = ObservableObjectPublisher()
    private let discoveryModel: any PeripheralDiscoveryModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing discoveryModel: any PeripheralDiscoveryModelProtocol, initialSearchQuery: String) {
        self.searchQuery = CurrentValueSubject<String, Never>(initialSearchQuery)
        
        self.discoveryModel = discoveryModel
        
        self.stateDidUpdate = discoveryModel
            .stateDidUpdate
            .combineLatest(searchQuery)
            .map { pair -> PeripheralSearchModelState in
                .from(discoveryState: pair.0, searchQuery: pair.1)
            }
            .eraseToAnyPublisher()
        
        searchQuery
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        discoveryModel.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
   
    
    
    public func startScan() {
        discoveryModel.startScan()
    }
    
    
    public func stopScan() {
        discoveryModel.stopScan()
    }
}


public func satisfy(searchQuery: String) -> (any PeripheralModelProtocol) -> Bool {
    if searchQuery.isEmpty {
        return { _ in true }
    }
    
    return { peripheral in
        let searchQuery = searchQuery.uppercased()
        
        if peripheral.state.uuid.uuidString.contains(searchQuery) {
            return true
        }
        
        switch peripheral.state.name {
        case .success(.some(let name)):
            if name.uppercased().contains(searchQuery) {
                return true
            }
        case .failure, .success(.none):
            break
        }
        
        switch peripheral.state.manufacturerData {
        case .some(.knownName(let manufacturer, let data)):
            if manufacturer.uppercased().contains(searchQuery) {
                return true
            }
            if HexEncoding.upper.encode(data: data).contains(searchQuery) {
                return true
            }
        case .some(.data(let data)):
            if HexEncoding.upper.encode(data: data).contains(searchQuery) {
                return true
            }
        case .none:
            break
        }
        
        return false
    }
}
