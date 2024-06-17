import Combine
import ConcurrentCombine
import BLEInternal
import CoreBluetoothTestable


public struct SearchQuery: RawRepresentable {
    public var rawValue: String
    
    
    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }
    
    
    public static func filter(state: PeripheralDiscoveryModelState, bySearchQuery searchQuery: SearchQuery) -> PeripheralDiscoveryModelState {
        
    }
    
    
    public static func match(searchQuery: SearchQuery, state: PeripheralModelState) -> Bool {
        let searchQuery = searchQuery.rawValue
        if searchQuery.isEmpty { return true }
        
        if state.uuid.uuidString.contains(searchQuery) {
            return true
        }
        
        switch state.name {
        case .success(.some(let name)):
            if name.uppercased().contains(searchQuery) {
                return true
            }
        case .failure, .success(.none):
            break
        }
        
        switch state.manufacturerData {
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


public enum PeripheralSearchModelDiscoveryState {
    case idle
    case ready
    case discovering([SearchablePeripheralModel])
    case discovered([SearchablePeripheralModel])
    case discoveryFailed(PeripheralDiscoveryModelFailure)

    
    public static func initialState() -> Self {
        .idle
    }


    public var models: Result<[SearchablePeripheralModel], PeripheralDiscoveryModelFailure> {
        switch self {
        case .discovering(let peripherals), .discovered(let peripherals):
            return .success(peripherals)
        case .idle, .ready:
            return .success([])
        case .discoveryFailed(let error):
            return .failure(error)
        }
    }
    
    
    public var isScanning: Bool {
        switch self {
        case .discovering:
            return true
        case .idle, .ready, .discoveryFailed, .discovered:
            return false
        }
    }
    
    
    public var canStartScan: Bool {
        switch self {
        case .ready, .discovered, .discoveryFailed(.unspecified):
            return true
        case .idle, .discovering, .discoveryFailed(.powerOff), .discoveryFailed(.unauthorized), .discoveryFailed(.unsupported):
            return false
        }
    }
    
    
    public var canStopScan: Bool {
        switch self {
        case .idle, .ready, .discoveryFailed, .discovered:
            return false
        case .discovering:
            return true
        }
    }
}


extension PeripheralSearchModelDiscoveryState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle:
            return ".idle"
        case .ready:
            return ".ready"
        case .discovering(let peripherals):
            return ".discovering([\(peripherals.count) peripherals])"
        case .discovered(let peripherals):
            return ".discovered([\(peripherals.count) peripherals])"
        case .discoveryFailed(let error):
            return ".discoveryFailed(\(error))"
        }
    }
}


public struct PeripheralSearchModelState {
    public var discovery: PeripheralSearchModelDiscoveryState
    public var searchQuery: String
    
    
    public init(discovery: PeripheralSearchModelDiscoveryState, searchQuery: String) {
        self.discovery = discovery
        self.searchQuery = searchQuery
    }
    
    
    public static func initialState(searchQuery: String) -> Self {
        .init(
            discovery: .initialState(),
            searchQuery: searchQuery
        )
    }
}


extension PeripheralSearchModelState: CustomStringConvertible {
    public var description: String {
        "PeripheralSearchModelState(discoveryState: \(discovery.description), searchQuery: \(searchQuery))"
    }
}


public protocol PeripheralSearchModelProtocol: Actor, ObservableObject where ObjectWillChangePublisher == AnyPublisher<Void, Never> {
    nonisolated var stateDidUpdate: AnyPublisher<PeripheralSearchModelState, Never> { get }
    nonisolated var searchQuery: ConcurrentValueSubject<String, Never> { get }
    func startScan()
    func stopScan()
}


extension PeripheralSearchModelProtocol {
    public func eraseToAny() -> AnyPeripheralSearchModel {
        AnyPeripheralSearchModel(self)
    }
}


public actor AnyPeripheralSearchModel: PeripheralSearchModelProtocol {
    nonisolated private let base: any PeripheralSearchModelProtocol
    
    nonisolated public var stateDidUpdate: AnyPublisher<PeripheralSearchModelState, Never> { base.stateDidUpdate }
    nonisolated public var objectWillChange: AnyPublisher<Void, Never> { base.objectWillChange }
    nonisolated public var searchQuery: ConcurrentValueSubject<String, Never> { base.searchQuery }
    
    
    public init(_ base: any PeripheralSearchModelProtocol) {
        self.base = base
    }
    
    
    public func startScan() {
        Task { await base.startScan() }
    }
    
    public func stopScan() {
        Task { await base.stopScan() }
    }
}


public actor PeripheralSearchModel: PeripheralSearchModelProtocol {
    nonisolated public let stateDidUpdate: AnyPublisher<PeripheralSearchModelState, Never>
    nonisolated public let searchQuery: ConcurrentValueSubject<String, Never>
    
    nonisolated public let objectWillChange: AnyPublisher<Void, Never>
    
    private let discoveryModel: any PeripheralDiscoveryModelProtocol
    
    
    public init(observing discoveryModel: any PeripheralDiscoveryModelProtocol, initialSearchQuery: String) {
        self.searchQuery = ConcurrentValueSubject<String, Never>(initialSearchQuery)
        
        self.discoveryModel = discoveryModel
        
        let stateDidUpdate = discoveryModel
            .stateDidUpdate
            .combineLatest(searchQuery)
            .map { pair -> PeripheralSearchModelState in
                .from(discovery: pair.0, searchQuery: pair.1)
            }
            .eraseToAnyPublisher()
        
        self.objectWillChange = discoveryModel.stateDidUpdate
            .map { _ in () }
            .merge(with: searchQuery.map { _ in () })
            .eraseToAnyPublisher()
    }
   
    
    
    public func startScan() {
        Task { await discoveryModel.startScan() }
    }
    
    
    public func stopScan() {
        Task { await discoveryModel.stopScan() }
    }
}
