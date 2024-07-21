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
            if name.uppercased().contains(searchQuery) {
                return true
            }
        case .failure, .success(.none):
            break
        }
        
        switch state.manufacturerData {
        case .some(.knownName(let manufacturer, let data)):
            if manufacturer.name.uppercased().contains(searchQuery) {
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
        case .idle(requestedDiscovery: let requestedDiscovery):
            return .idle(requestedDiscovery: requestedDiscovery)
        case .ready:
            return .ready
        case .discovering(let peripherals, let discovered):
            return .discovering(await filter(peripherals: peripherals, bySearchQuery: searchQuery), discovered)
        case .discovered(let peripherals, let discovered):
            return .discovered(await filter(peripherals: peripherals, bySearchQuery: searchQuery), discovered)
        case .discoveryFailed(let error):
            return .discoveryFailed(error)
        }
    }

    
    private static func filter(peripherals: [AnyPeripheralModel], bySearchQuery searchQuery: SearchQuery) async -> [AnyPeripheralModel] {
        return peripherals
            .filter { searchQuery.match(state: $0.state) }
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
        "(discovery: \(discovery.description), searchQuery: \(searchQuery))"
    }
}


extension PeripheralSearchModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        "(discovery: \(discovery.debugDescription), searchQuery: \(searchQuery.rawValue.count) chars)"
    }
}


public protocol PeripheralSearchModelProtocol: StateMachineProtocol<PeripheralSearchModelState> {
    nonisolated var searchQuery: ConcurrentValueSubject<SearchQuery, Never> { get }
    nonisolated func startScan()
    nonisolated func stopScan()
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
    nonisolated public var searchQuery: ConcurrentValueSubject<SearchQuery, Never> { base.searchQuery }
   
    
    public init(_ base: any PeripheralSearchModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func startScan() {
        base.startScan()
    }
    
    nonisolated public func stopScan() {
        base.stopScan()
    }
}


public final actor PeripheralSearchModel: PeripheralSearchModelProtocol {
    nonisolated public var state: State {
        .init(discovery: discoveryModel.state, searchQuery: searchQuery.value)
    }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    nonisolated public let searchQuery: ConcurrentValueSubject<SearchQuery, Never>
    
    private let discoveryModel: any PeripheralDiscoveryModelProtocol
    
    
    public init(observing discoveryModel: any PeripheralDiscoveryModelProtocol, initialSearchQuery: SearchQuery) {
        self.searchQuery = ConcurrentValueSubject<SearchQuery, Never>(initialSearchQuery)
        
        self.discoveryModel = discoveryModel
        
        stateDidChange = discoveryModel.stateDidChange
            .combineLatest(searchQuery)
            .map { (discovery, searchQuery) in
                PeripheralSearchModelState(discovery: discovery, searchQuery: searchQuery)
            }
            .eraseToAnyPublisher()
    }
   
    
    nonisolated public func startScan() {
        discoveryModel.startScan()
    }
    
    
    nonisolated public func stopScan() {
        discoveryModel.stopScan()
    }
}
