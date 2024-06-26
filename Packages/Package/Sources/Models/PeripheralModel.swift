import Foundation
import Combine
import ConcurrentCombine
import CoreBluetooth
import CoreBluetoothTestable
import CoreBluetoothTasks
import ModelFoundation
import Catalogs


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


public struct PeripheralModelState: Equatable {
    public var uuid: UUID
    public var connection: ConnectionModelState
    public var name: Result<String?, PeripheralModelFailure>
    public var rssi: Result<NSNumber, PeripheralModelFailure>
    public var manufacturerData: ManufacturerData?
    public var discovery: ServiceDiscoveryModelState

    
    public init(
        uuid: UUID,
        name: Result<String?, PeripheralModelFailure>,
        rssi: Result<NSNumber, PeripheralModelFailure>,
        manufacturerData: ManufacturerData?,
        connection: ConnectionModelState,
        discovery: ServiceDiscoveryModelState
    ) {
        self.uuid = uuid
        self.name = name
        self.rssi = rssi
        self.manufacturerData = manufacturerData
        self.connection = connection
        self.discovery = discovery
    }
    
    
    public static func initialState(
        uuid: UUID,
        name: String?,
        rssi: NSNumber,
        manufacturerData: ManufacturerData?,
        isConnectable: Bool,
        discovery: ServiceDiscoveryModelState
    ) -> Self {
        return PeripheralModelState(
            uuid: uuid,
            name: .success(name),
            rssi: .success(rssi),
            manufacturerData: manufacturerData,
            connection: isConnectable
                ? .disconnected // T2
                : .notConnectable, // T1
            discovery: discovery
        )
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
    func readRSSI()
    func discover()
    func connect()
    func disconnect()
}


extension PeripheralModelProtocol {
    nonisolated public func eraseToAny() -> AnyPeripheralModel {
        AnyPeripheralModel(self)
    }
}


public actor AnyPeripheralModel: PeripheralModelProtocol {
    nonisolated public var state: State { base.state }
    nonisolated public var stateDidChange: AnyPublisher<State, Never> { base.stateDidChange }
    nonisolated public var id: UUID { base.id }
    
    private let base: any PeripheralModelProtocol
    
    
    public init(_ base: any PeripheralModelProtocol) {
        self.base = base
    }
    
    
    public func readRSSI() {
        Task { await base.readRSSI() }
    }
    
    
    public func discover() {
        Task { await base.discover() }
    }
    
    
    public func connect() {
        Task { await base.connect() }
    }
    
    
    public func disconnect() {
        Task { await base.disconnect() }
    }
}


extension AnyPeripheralModel: Equatable {
    public static func == (lhs: AnyPeripheralModel, rhs: AnyPeripheralModel) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state
    }
}


public actor PeripheralModel: PeripheralModelProtocol {
    nonisolated public var state: State {
        return PeripheralModelState(
            uuid: id,
            name: nameSubject.projected,
            rssi: rssiSubject.projected,
            manufacturerData: manufacturerData,
            connection: model.state.connection,
            discovery: model.state.discovery
        )
    }
    nonisolated public let stateDidChange: AnyPublisher<PeripheralModelState, Never>
    
    nonisolated public let id: UUID
    nonisolated private let manufacturerData: ManufacturerData?
    nonisolated private let nameSubject: ProjectedValueSubject<Result<String?, PeripheralModelFailure>, Never>
    nonisolated private let rssiSubject: ProjectedValueSubject<Result<NSNumber, PeripheralModelFailure>, Never>

    nonisolated private let peripheral: any PeripheralProtocol
    nonisolated private let model: any ConnectableDiscoveryModelProtocol<AnyServiceModel, PeripheralModelFailure>
    private var cancellables = Set<AnyCancellable>()
    

    public init(
        representing peripheral: any PeripheralProtocol,
        withRSSI rssi: NSNumber,
        withAdvertisementData advertisementData: [String: Any],
        connectingWith connectionModel: any ConnectionModelProtocol
    ) {
        self.id = peripheral.identifier
        
        let manufacturerData = ManufacturerData.from(advertisementData: advertisementData)
        self.manufacturerData = manufacturerData
        
        let nameSubject = ProjectedValueSubject<Result<String?, PeripheralModelFailure>, Never>(.success(peripheral.name))
        self.nameSubject = nameSubject
        let rssiSubject = ProjectedValueSubject<Result<NSNumber, PeripheralModelFailure>, Never>(.success(rssi))
        self.rssiSubject = rssiSubject
        
        let discoveryModel = DiscoveryModel<AnyServiceModel, PeripheralModelFailure>(
            discoveringBy: serviceDiscoveryStrategy(
                onPeripheral: peripheral,
                connectingBy: connectionModel
            )
        )

        self.peripheral = peripheral
        
        let model = ConnectableDiscoveryModel(
            discoveringBy: discoveryModel,
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
    
    
    public func readRSSI() {
        peripheral.readRSSI()
    }
    
    public func discover() {
        Task { await model.discover() }
    }
    
    public func connect() {
        Task { await model.connect() }
    }
    
    public func disconnect() {
        Task { await model.disconnect() }
    }
}


private func serviceDiscoveryStrategy(
    onPeripheral peripheral: any PeripheralProtocol,
    connectingBy connectionModel: any ConnectionModelProtocol
) -> () async -> Result<[AnyServiceModel], PeripheralModelFailure> {
    return {
        await DiscoveryTask
            .discoverServices(onPeripheral: peripheral)
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
