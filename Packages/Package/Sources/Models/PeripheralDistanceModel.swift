import Foundation
import CoreBluetooth
import Combine
import ConcurrentCombine
import ModelFoundation


public struct PeripheralDistanceState: Equatable, Sendable {
    public let distance: Double?
    public let environmentalFactor: Double
    public let txPower: Double
    
    
    public init(distance: Double?, environmentalFactor: Double, txPower: Double) {
        self.distance = distance
        self.environmentalFactor = environmentalFactor
        self.txPower = txPower
    }
    
    
    public static func from(peripheral: PeripheralModelState, environmentalFactor: Double, txPower: Double) -> PeripheralDistanceState {
        switch peripheral.rssi {
        case .failure:
            return .init(distance: nil, environmentalFactor: environmentalFactor, txPower: txPower)
            
        case .success(let rssi):
            let rssi = rssi.doubleValue
            return .init(
                distance: pow(10.0, (txPower - rssi) / (10 * environmentalFactor)),
                environmentalFactor: 2.0,
                txPower: txPower
            )
        }
    }
}


extension PeripheralDistanceState: CustomStringConvertible {
    public var description: String {
        let d: String
        if let distance {
            d = String(format: "%.1f", distance)
        } else {
            d = "nil"
        }
        return String(format: "(distance: %@, environmentalFactor: %.1f, txPower: %.1f)", d, environmentalFactor, txPower)
    }
}


extension PeripheralDistanceState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return String(format: "(distance: %@, environmentalFactor: %.1f, txPower: %.1f)", distance == nil ? ".some" : ".none", environmentalFactor, txPower)
    }
}


public protocol PeripheralDistanceModelProtocol: StateMachineProtocol<PeripheralDistanceState> {
    nonisolated func update(environmentalFactorTo environmentalFactor: Double)
    nonisolated func update(txPowerTo txPower: Double)
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
    
    nonisolated public func update(txPowerTo txPower: Double) {
        base.update(txPowerTo: txPower)
    }
}


public final actor PeripheralDistanceModel: PeripheralDistanceModelProtocol {
    nonisolated private let peripheral: any PeripheralModelProtocol
    nonisolated private let environmentalFactorSubject: ConcurrentValueSubject<Double, Never>
    nonisolated private let txPowerSubject: ConcurrentValueSubject<Double, Never>
    
    nonisolated public var state: PeripheralDistanceState {
        .from(peripheral: peripheral.state, environmentalFactor: environmentalFactorSubject.value, txPower: txPowerSubject.value)
    }
    nonisolated public let stateDidChange: AnyPublisher<PeripheralDistanceState, Never>
    
    
    public init(observing peripheral: any PeripheralModelProtocol, withEnvironmentalFactor environmentalFactor: Double) {
        self.peripheral = peripheral
        let environmentalFactorSubject = ConcurrentValueSubject<Double, Never>(environmentalFactor)
        self.environmentalFactorSubject = environmentalFactorSubject
        
        let txPower: Double
        if let rawTxPower = peripheral.state.advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
            txPower = rawTxPower.doubleValue
        } else {
            txPower = -50
        }

        let txPowerSubject = ConcurrentValueSubject<Double, Never>(txPower)
        self.txPowerSubject = txPowerSubject
        
        self.stateDidChange = Publishers
            .CombineLatest(Publishers.CombineLatest(
                peripheral.stateDidChange,
                environmentalFactorSubject
            ), txPowerSubject)
            .map { pair, txPower in
                let (peripheralState, environmentalFactor) = pair
                return .from(peripheral: peripheralState, environmentalFactor: environmentalFactor, txPower: txPower)
            }
            .eraseToAnyPublisher()
    }
    
    
    nonisolated public func update(environmentalFactorTo environmentalFactor: Double) {
        Task { await environmentalFactorSubject.change { _ in environmentalFactor } }
    }
    
    
    nonisolated public func update(txPowerTo txPower: Double) {
        Task { await txPowerSubject.change { _ in txPower } }
    }
}
