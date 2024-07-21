import Foundation
import Combine
import ConcurrentCombine
import BLEInternal
import CoreBluetoothTestable
import ModelFoundation
import TaskExtensions


public struct SearchQuery: RawRepresentable, Equatable, Codable, ExpressibleByStringLiteral {
    public typealias StringLiteralType = Swift.StringLiteralType
    public typealias ExtendedGraphemeClusterLiteralType = Swift.ExtendedGraphemeClusterType
    public typealias UnicodeScalarLiteralType = UnicodeScalarType
    
    public var rawValue: String
    
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
    
    
    public func match(state: PeripheralModelState) -> Bool {
        let searchQuery = self.rawValue
        if searchQuery.isEmpty { return true }
        
        if state.uuid.uuidString.contains(searchQuery) {
            return true
        }
        
        switch state.name {
        case .success(.some(let name)):
            if name.contains(searchQuery) {
                return true
            }
        case .failure, .success(.none):
            break
        }
        
        return false
    }

    
    public static func filter(peripherals: [AnyPeripheralModel], bySearchQuery searchQuery: SearchQuery) -> [AnyPeripheralModel] {
        return peripherals
            .filter { searchQuery.match(state: $0.state) }
    }
}


extension PeripheralDiscoveryModelState {
    public func filter(bySearchQuery searchQuery: SearchQuery) -> Self {
        switch self {
        case .idle(requestedDiscovery: let requestedDiscovery):
            return .idle(requestedDiscovery: requestedDiscovery)
        case .ready:
            return .ready
        case .discovering(let peripherals, let discovered):
            return .discovering(SearchQuery.filter(peripherals: peripherals, bySearchQuery: searchQuery), discovered)
        case .discovered(let peripherals, let discovered):
            return .discovered(SearchQuery.filter(peripherals: peripherals, bySearchQuery: searchQuery), discovered)
        case .discoveryFailed(let error):
            return .discoveryFailed(error)
        }
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
    
    
    public static func from(discovery: PeripheralDiscoveryModelState, searchQuery: SearchQuery) -> Self {
        .init(
            discovery: discovery.filter(bySearchQuery: searchQuery),
            searchQuery: searchQuery
        )
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
        "(discovery: \(discovery.description), searchQuery: \(searchQuery))"
    }
}


extension PeripheralSearchModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        "(discovery: \(discovery.debugDescription), searchQuery: \(searchQuery.rawValue.count) chars)"
    }
}


public protocol PeripheralSearchModelProtocol: StateMachineProtocol<PeripheralSearchModelState> {
    nonisolated func startScan()
    nonisolated func stopScan()
    nonisolated func updateSearchQuery(to searchQuery: SearchQuery)
}


extension PeripheralSearchModelProtocol {
    nonisolated public func eraseToAny() -> AnyPeripheralSearchModel {
        AnyPeripheralSearchModel(self)
    }
}


public final actor AnyPeripheralSearchModel: PeripheralSearchModelProtocol {
    private let base: any PeripheralSearchModelProtocol
    
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
   
    
    public init(_ base: any PeripheralSearchModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func startScan() {
        base.startScan()
    }
    
    nonisolated public func stopScan() {
        base.stopScan()
    }
    
    nonisolated public func updateSearchQuery(to searchQuery: SearchQuery) {
        base.updateSearchQuery(to: searchQuery)
    }
}


public final actor PeripheralSearchModel: PeripheralSearchModelProtocol {
    nonisolated public var state: State {
        .init(discovery: discoveryModel.state, searchQuery: searchQuerySubject.value)
    }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    nonisolated private let searchQuerySubject: ConcurrentValueSubject<SearchQuery, Never>
    
    private let discoveryModel: any PeripheralDiscoveryModelProtocol
    
    
    public init(observing discoveryModel: any PeripheralDiscoveryModelProtocol, initialSearchQuery: SearchQuery) {
        let searchQuerySubject = ConcurrentValueSubject<SearchQuery, Never>(initialSearchQuery)
        self.searchQuerySubject = searchQuerySubject
        self.discoveryModel = discoveryModel
        self.stateDidChange = discoveryModel.stateDidChange
            .combineLatest(searchQuerySubject)
            .map { (discovery, searchQuery) in
                return PeripheralSearchModelState.from(discovery: discovery, searchQuery: searchQuery)
            }
            .eraseToAnyPublisher()
    }
   
    
    nonisolated public func startScan() {
        discoveryModel.startScan()
    }
    
    
    nonisolated public func stopScan() {
        discoveryModel.stopScan()
    }
    
    
    nonisolated public func updateSearchQuery(to searchQuery: SearchQuery) {
        Task {
            await self.searchQuerySubject.change { _ in searchQuery }
        }
    }
}
