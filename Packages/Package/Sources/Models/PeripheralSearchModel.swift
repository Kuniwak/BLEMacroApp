import Foundation
import Combine
import ConcurrentCombine
import BLEInternal
import CoreBluetoothTestable
import ModelFoundation
import TaskExtensions


public struct SearchQuery: RawRepresentable, Equatable, Codable {
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
        case .discovering(.some(let peripherals)):
            return .discovering(await filter(peripherals: peripherals, bySearchQuery: searchQuery))
        case .discovering(.none):
            return .discovering(nil)
        case .discovered(let peripherals):
            return .discovered(await filter(peripherals: peripherals, bySearchQuery: searchQuery))
        case .discoveryFailed(let error):
            return .discoveryFailed(error)
        }
    }

    
    private static func filter(peripherals: [AnyPeripheralModel], bySearchQuery searchQuery: SearchQuery) async -> [AnyPeripheralModel] {
        return peripherals
            .filter { match(searchQuery: searchQuery, state: $0.state) }
    }
}


extension SearchQuery: CustomStringConvertible {
    public var description: String { rawValue }
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


public protocol PeripheralSearchModelProtocol: StateMachineProtocol<PeripheralSearchModelState> {
    nonisolated var searchQuery: ProjectedValueSubject<SearchQuery, Never> { get }
    func startScan()
    func stopScan()
}


extension PeripheralSearchModelProtocol {
    nonisolated public func eraseToAny() -> AnyPeripheralSearchModel {
        AnyPeripheralSearchModel(self)
    }
}


public actor AnyPeripheralSearchModel: PeripheralSearchModelProtocol {
    private let base: any PeripheralSearchModelProtocol
    
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    nonisolated public var searchQuery: ProjectedValueSubject<SearchQuery, Never> { base.searchQuery }
   
    
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
    nonisolated public var state: State {
        .init(discovery: discoveryModel.state, searchQuery: searchQuery.projected)
    }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    nonisolated public let searchQuery: ProjectedValueSubject<SearchQuery, Never>
    
    private let discoveryModel: any PeripheralDiscoveryModelProtocol
    
    
    public init(observing discoveryModel: any PeripheralDiscoveryModelProtocol, initialSearchQuery: SearchQuery) {
        self.searchQuery = ProjectedValueSubject<SearchQuery, Never>(initialSearchQuery)
        
        self.discoveryModel = discoveryModel
        
        stateDidChange = discoveryModel.stateDidChange
            .combineLatest(searchQuery)
            .map { (discovery, searchQuery) in
                PeripheralSearchModelState(discovery: discovery, searchQuery: searchQuery)
            }
            .eraseToAnyPublisher()
    }
   
    
    public func startScan() {
        Task { await discoveryModel.startScan() }
    }
    
    
    public func stopScan() {
        Task { await discoveryModel.stopScan() }
    }
}
