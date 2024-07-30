import Foundation
import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothTestable
import BLETasks
import ModelFoundation
import Catalogs
import MirrorDiffKit


public struct PeripheralModelFailure: Error, CustomStringConvertible, Equatable {
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


public typealias ServiceDiscoveryModelState = DiscoveryModelState<AnyServiceModel, PeripheralModelFailure>


public struct PeripheralModelState {
    public var uuid: UUID
    public var connection: ConnectionModelState
    public var name: Result<String?, PeripheralModelFailure>
    public var rssi: Result<NSNumber, PeripheralModelFailure>
    public var advertisementData: [String: Any]
    public var manufacturerData: ManufacturerData?
    public var discovery: ServiceDiscoveryModelState

    
    public init(
        uuid: UUID,
        name: Result<String?, PeripheralModelFailure>,
        rssi: Result<NSNumber, PeripheralModelFailure>,
        manufacturerData: ManufacturerData?,
        advertisementData: [String: Any],
        connection: ConnectionModelState,
        discovery: ServiceDiscoveryModelState
    ) {
        self.uuid = uuid
        self.name = name
        self.rssi = rssi
        self.manufacturerData = manufacturerData
        self.advertisementData = advertisementData
        self.connection = connection
        self.discovery = discovery
    }
    
    
    public static func initialState(
        uuid: UUID,
        name: String?,
        rssi: NSNumber,
        manufacturerData: ManufacturerData?,
        advertisementData: [String: Any],
        isConnectable: Bool,
        discovery: ServiceDiscoveryModelState
    ) -> Self {
        return PeripheralModelState(
            uuid: uuid,
            name: .success(name),
            rssi: .success(rssi),
            manufacturerData: manufacturerData,
            advertisementData: advertisementData,
            connection: isConnectable
                ? .disconnected // T2
                : .notConnectable, // T1
            discovery: discovery
        )
    }
}


extension PeripheralModelState: Equatable {
    public static func == (lhs: PeripheralModelState, rhs: PeripheralModelState) -> Bool {
        lhs.uuid == rhs.uuid
            && lhs.name == rhs.name
            && lhs.rssi == rhs.rssi
            && lhs.manufacturerData == rhs.manufacturerData
            && lhs.advertisementData =~ rhs.advertisementData
            && lhs.connection == rhs.connection
            && lhs.discovery == rhs.discovery
    }
}


extension PeripheralModelState: CustomStringConvertible {
    public var description: String {
        let name: String
        switch self.name {
        case .success(.some(let value)):
            name = value
        case .success(.none):
            name = "nil"
        case .failure(let error):
            name = error.description
        }
        
        let rssi: String
        switch self.rssi {
        case .success(let value):
            rssi = "\(value)"
        case .failure(let error):
            rssi = error.description
        }
        
        return "(uuid: \(uuid), name: \(name), rssi: \(rssi), manufacturerData: \(manufacturerData?.description ?? "nil"), connection: \(connection.description))"
    }
}


extension PeripheralModelState: CustomDebugStringConvertible {
    public var debugDescription: String {
        let name: String
        switch self.name {
        case .success(.some):
            name = ".success(.some)"
        case .success(.none):
            name = ".success(.none)"
        case .failure:
            name = ".failure"
        }
        
        let rssi: String
        switch self.rssi {
        case .success:
            rssi = ".success"
        case .failure:
            rssi = ".failure"
        }
        
        return "(uuid: \(uuid.uuidString.prefix(2))...\(uuid.uuidString.suffix(2)), name: \(name), rssi: \(rssi), manufacturerData: \(manufacturerData?.debugDescription ?? "nil"), connection: \(connection.debugDescription))"
    }
}


public protocol PeripheralModelProtocol: StateMachineProtocol<PeripheralModelState>, Identifiable<UUID> {
    nonisolated func readRSSI()
    nonisolated func discover()
    nonisolated func connect()
    nonisolated func disconnect()
}


extension PeripheralModelProtocol {
    nonisolated public func eraseToAny() -> AnyPeripheralModel {
        AnyPeripheralModel(self)
    }
}


public final actor AnyPeripheralModel: PeripheralModelProtocol {
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    nonisolated public var id: UUID { base.id }
    
    private let base: any PeripheralModelProtocol
    
    
    public init(_ base: any PeripheralModelProtocol) {
        self.base = base
    }
    
    
    nonisolated public func readRSSI() {
        base.readRSSI()
    }
    
    
    nonisolated public func discover() {
        base.discover()
    }
    
    
    nonisolated public func connect() {
        base.connect()
    }
    
    
    nonisolated public func disconnect() {
        base.disconnect()
    }
}


extension AnyPeripheralModel: Equatable {
    public static func == (lhs: AnyPeripheralModel, rhs: AnyPeripheralModel) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}


public final actor PeripheralModel: PeripheralModelProtocol {
    nonisolated public var state: State {
        return PeripheralModelState(
            uuid: id,
            name: nameSubject.value,
            rssi: rssiSubject.value,
            manufacturerData: manufacturerData,
            advertisementData: advertisementData,
            connection: model.state.connection,
            discovery: model.state.discovery
        )
    }
    nonisolated public let stateDidChange: AnyPublisher<PeripheralModelState, Never>
    
    nonisolated public var id: UUID { peripheral.identifier }
    nonisolated private let manufacturerData: ManufacturerData?
    nonisolated private let advertisementData: [String: Any]
    nonisolated private let nameSubject: ConcurrentValueSubject<Result<String?, PeripheralModelFailure>, Never>
    nonisolated private let rssiSubject: ConcurrentValueSubject<Result<NSNumber, PeripheralModelFailure>, Never>

    nonisolated private let peripheral: any PeripheralProtocol
    nonisolated private let model: any ConnectableDiscoveryModelProtocol<AnyServiceModel, PeripheralModelFailure>
    private var cancellables = Set<AnyCancellable>()
    

    public init(
        representing peripheral: any PeripheralProtocol,
        withRSSI rssi: NSNumber,
        withAdvertisementData advertisementData: [String: Any],
        connectingWith connectionModel: any ConnectionModelProtocol
    ) {
        self.peripheral = peripheral

        let manufacturerData = ManufacturerData.from(advertisementData: advertisementData)
        self.manufacturerData = manufacturerData
        self.advertisementData = advertisementData
        
        let nameSubject = ConcurrentValueSubject<Result<String?, PeripheralModelFailure>, Never>(.success(peripheral.name))
        self.nameSubject = nameSubject
        let rssiSubject = ConcurrentValueSubject<Result<NSNumber, PeripheralModelFailure>, Never>(.success(rssi))
        self.rssiSubject = rssiSubject

        let model = ConnectableDiscoveryModel(
            discoveringBy: DiscoveryModel<AnyServiceModel, PeripheralModelFailure>(
                discoveringBy: serviceDiscoveryStrategy(
                    onPeripheral: peripheral,
                    connectingBy: connectionModel
                )
            ),
            connectingBy: connectionModel
        )
        self.model = model
        
        self.stateDidChange = model.stateDidChange
            .combineLatest(nameSubject, rssiSubject)
            .map { state, name, rssi -> PeripheralModelState in
                PeripheralModelState(
                    uuid: peripheral.identifier,
                    name: name,
                    rssi: rssi,
                    manufacturerData: manufacturerData,
                    advertisementData: advertisementData,
                    connection: state.connection,
                    discovery: state.discovery
                )
            }
            .eraseToAnyPublisher()
        
        var mutableCancellables = Set<AnyCancellable>()
        
        peripheral.didUpdateRSSI
            .sink { [weak self] resp in
                guard let self else { return }
                
                Task {
                    await self.rssiSubject.change { _ in
                        if let rssi = resp.rssi {
                            return .success(rssi)
                        } else {
                            return .failure(.init(wrapping: resp.error))
                        }
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        peripheral.didUpdateName
            .sink { [weak self] name in
                guard let self else { return }
                
                Task {
                    await self.nameSubject.change { _ in
                        if let name = name {
                            return .success(name)
                        } else {
                            return .failure(.init(description: "No name"))
                        }
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        peripheral.didReadRSSI
            .sink { [weak self] resp in
                guard let self else { return }
                
                Task {
                    await self.rssiSubject.change { _ in
                        if let rssi = resp.rssi {
                            return .success(rssi)
                        } else {
                            return .failure(.init(wrapping: resp.error))
                        }
                    }
                }
            }
            .store(in: &mutableCancellables)
        
        let cancellables = mutableCancellables
        Task { await self.store(cancellables: cancellables) }
    }
    
    
    private func store(cancellables: Set<AnyCancellable>) {
        self.cancellables = self.cancellables.union(cancellables)
    }
    
    
    nonisolated public func readRSSI() {
        peripheral.readRSSI()
    }
    
    nonisolated public func discover() {
        model.discover()
    }
    
    nonisolated public func connect() {
        model.connect()
    }
    
    nonisolated public func disconnect() {
        model.disconnect()
    }
}


private func serviceDiscoveryStrategy(
    onPeripheral peripheral: any PeripheralProtocol,
    connectingBy connectionModel: any ConnectionModelProtocol
) -> () async -> Result<[AnyServiceModel], PeripheralModelFailure> {
    return {
        await PeripheralTasks(peripheral: peripheral)
            .discoverServices()
            .map { services in
                services.map { service in
                    ServiceModel(
                        representing: service,
                        onPeripheral: peripheral,
                        controlledBy: connectionModel
                    ).eraseToAny()
                }
            }
            .mapError(PeripheralModelFailure.init(wrapping:))
    }
}
