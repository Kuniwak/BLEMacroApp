import Foundation
import CoreBluetooth
import Combine
import ConcurrentCombine
import ModelFoundation


public struct PeripheralDistanceState: Equatable, Sendable {
    public let distance: Double?
    public let environmentalFactor: Double
    
    
    public init(distance: Double?, environmentalFactor: Double) {
        self.distance = distance
        self.environmentalFactor = environmentalFactor
    }
    
    
    public static func from(peripheral: PeripheralModelState, environmentalFactor: Double) -> PeripheralDistanceState {
        guard let txPower = peripheral.advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber else {
            return .init(distance: nil, environmentalFactor: environmentalFactor)
        }
        
        switch peripheral.rssi {
        case .failure:
            return .init(distance: nil, environmentalFactor: environmentalFactor)
            
        case .success(let rssi):
            let rssi = rssi.doubleValue
            let txPower = txPower.doubleValue
            return .init(
                distance: pow(10.0, (txPower - rssi) / (10 * environmentalFactor)),
                environmentalFactor: 2.0
            )
        }
    }
}


extension PeripheralDistanceState: CustomStringConvertible {
    public var description: String {
        return "(distance: \(distance?.description ?? "N/A"), environmentalFactor: \(environmentalFactor))"
    }
}


extension PeripheralDistanceState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "(distance: \(distance == nil ? ".none" : ".some"), environmentalFactor: \(environmentalFactor))"
    }
}


public protocol PeripheralDistanceModelProtocol: StateMachineProtocol<PeripheralDistanceState> {
    nonisolated func update(environmentalFactorTo environmentalFactor: Double)
}


extension PeripheralDistanceModelProtocol {
    nonisolated public func eraseToAny() -> AnyPeripheralDistanceModel {
        return AnyPeripheralDistanceModel(self)
    }
}


public final actor AnyPeripheralDistanceModel: PeripheralDistanceModelProtocol {
    nonisolated public var state: PeripheralDistanceState { base.state }
    nonisolated public var stateDidChange: AnyPublisher<PeripheralDistanceState, Never> { base.stateDidChange }
    nonisolated private let base: any PeripheralDistanceModelProtocol
    
    public init(_ base: any PeripheralDistanceModelProtocol) {
        self.base = base
    }
    
    nonisolated public func update(environmentalFactorTo environmentalFactor: Double) {
        base.update(environmentalFactorTo: environmentalFactor)
    }
}


public final actor PeripheralDistanceModel: PeripheralDistanceModelProtocol {
    nonisolated private let peripheral: any PeripheralModelProtocol
    nonisolated private let environmentalFactorSubject: ConcurrentValueSubject<Double, Never>
    
    nonisolated public var state: PeripheralDistanceState {
        .from(peripheral: peripheral.state, environmentalFactor: environmentalFactorSubject.value)
    }
    nonisolated public let stateDidChange: AnyPublisher<PeripheralDistanceState, Never>
    
    
    public init(observing peripheral: any PeripheralModelProtocol, withEnvironmentalFactor environmentalFactor: Double) {
        self.peripheral = peripheral
        let environmentalFactorSubject = ConcurrentValueSubject<Double, Never>(environmentalFactor)
        self.environmentalFactorSubject = environmentalFactorSubject
        
        self.stateDidChange = Publishers
            .CombineLatest(
                peripheral.stateDidChange,
                environmentalFactorSubject
            )
            .map { peripheralState, environmentalFactor in
                .from(peripheral: peripheralState, environmentalFactor: environmentalFactor)
            }
            .eraseToAnyPublisher()
    }
    
    
    nonisolated public func update(environmentalFactorTo environmentalFactor: Double) {
        Task { await environmentalFactorSubject.change { _ in environmentalFactor } }
    }
}
