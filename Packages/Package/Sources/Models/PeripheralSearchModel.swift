import Combine
import ConcurrentCombine
import BLEInternal
import CoreBluetoothTestable
import TaskExtensions


public struct SearchQuery: RawRepresentable {
    public var rawValue: String
    
    
    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
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
    
    
    public static func filter(state: PeripheralDiscoveryModelState, bySearchQuery searchQuery: SearchQuery) async -> PeripheralDiscoveryModelState {
        switch state {
        case .idle:
            return .idle
        case .ready:
            return .ready
        case .discovering(let peripherals):
            return .discovering(await filter(peripherals: peripherals, bySearchQuery: searchQuery))
        case .discovered(let peripherals):
            return .discovered(await filter(peripherals: peripherals, bySearchQuery: searchQuery))
        case .discoveryFailed(let error):
            return .discoveryFailed(error)
        }
    }

    
    private static func filter(peripherals: [AnyPeripheralModel], bySearchQuery searchQuery: SearchQuery) async -> [AnyPeripheralModel] {
        let states = await Task.all(peripherals.map { peripheral in Task { await peripheral.state } } )
        return zip(peripherals, states.map { match(searchQuery: searchQuery, state: $0) } )
            .filter(\.1)
            .map(\.0)
    }
}


public struct PeripheralSearchModelState {
    public var discovery: PeripheralDiscoveryModelState
    public var searchQuery: SearchQuery
    
    
    public init(discovery: PeripheralDiscoveryModelState, searchQuery: SearchQuery) {
        self.discovery = discovery
        self.searchQuery = searchQuery
    }
    
    
    public static func initialState(searchQuery: SearchQuery) -> Self {
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


public protocol PeripheralSearchModelProtocol: StateMachine where State == PeripheralSearchModelState {
    nonisolated var searchQuery: ConcurrentValueSubject<SearchQuery, Never> { get }
    func startScan()
    func stopScan()
}


extension PeripheralSearchModelProtocol {
    public func eraseToAny() -> AnyPeripheralSearchModel {
        AnyPeripheralSearchModel(self)
    }
}


public actor AnyPeripheralSearchModel: PeripheralSearchModelProtocol {
    private let base: any PeripheralSearchModelProtocol
    
    nonisolated public var initialState: State { base.initialState }
    
    nonisolated public var stateDidUpdate: AnyPublisher<State, Never> { base.stateDidUpdate }
    nonisolated public var searchQuery: ConcurrentValueSubject<SearchQuery, Never> { base.searchQuery }
   
    
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
    nonisolated public let initialState: State
    
    private var stateDidUpdateSubject: CurrentValueSubject<State, Never>
    nonisolated public let stateDidUpdate: AnyPublisher<State, Never>
    public let searchQuery: ConcurrentValueSubject<SearchQuery, Never>
    
    private let discoveryModel: any PeripheralDiscoveryModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing discoveryModel: any PeripheralDiscoveryModelProtocol, initialSearchQuery: SearchQuery) {
        self.initialState = PeripheralSearchModelState(discovery: discoveryModel.initialState, searchQuery: initialSearchQuery)
        self.searchQuery = ConcurrentValueSubject<SearchQuery, Never>(initialSearchQuery)
        
        self.discoveryModel = discoveryModel
        
        let stateDidUpdateSubject = CurrentValueSubject<State, Never>(.initialState(searchQuery: initialSearchQuery))
        self.stateDidUpdateSubject = stateDidUpdateSubject
        self.stateDidUpdate = stateDidUpdateSubject.eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        discoveryModel
            .stateDidUpdate
            .combineLatest(searchQuery)
            .mapAsync { (state, searchQuery) async in
                PeripheralSearchModelState(
                    discovery: await SearchQuery.filter(state: state, bySearchQuery: searchQuery),
                    searchQuery: searchQuery
                )
            }
            .assign(to: \.value, on: stateDidUpdateSubject)
            .store(in: &mutableCancellables)
        
        let cancellables = mutableCancellables
        Task { await self.store(cancellables: cancellables) }
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables.formUnion(cancellables)
    }
   
    
    public func startScan() {
        Task { await discoveryModel.startScan() }
    }
    
    
    public func stopScan() {
        Task { await discoveryModel.stopScan() }
    }
}
