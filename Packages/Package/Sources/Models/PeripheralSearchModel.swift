import Foundation
import Combine
import ConcurrentCombine
import BLEInternal
import CoreBluetoothTestable
import ModelFoundation
import TaskExtensions



public struct PeripheralSearchModelState {
    public var discovery: PeripheralDiscoveryModelState
    public var searchQuery: SearchQuery
    
    
    public init(discovery: PeripheralDiscoveryModelState, searchQuery: SearchQuery) {
        self.discovery = discovery
        self.searchQuery = searchQuery
    }
    
    
    public var isFailed: Bool {
        discovery.isFailed
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
