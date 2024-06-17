import Combine
import CoreBluetoothTestable


public struct DiscoveryTaskFailure: Error, CustomStringConvertible {
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


public enum DiscoveryTask {
    public static func discoverServices(onPeripheral peripheral: any PeripheralProtocol) async -> Result<[any ServiceProtocol], DiscoveryTaskFailure> {
        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = peripheral.didDiscoverServices
                .sink { resp in
                    defer { cancellable?.cancel() }
                    
                    if let services = resp.services {
                        continuation.resume(returning: .success(services))
                    } else {
                        continuation.resume(returning: .failure(.init(wrapping: resp.error)))
                    }
                }

            peripheral.discoverServices(nil)
        }
    }
    
    
    public static func discoverCharacteristics(
        forService service: any ServiceProtocol,
        onPeripheral peripheral: any PeripheralProtocol
    ) async -> Result<[any CharacteristicProtocol], DiscoveryTaskFailure> {
        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = peripheral.didDiscoverCharacteristicsForService
                .sink { resp in
                    guard resp.service.uuid == service.uuid else { return }
                    defer { cancellable?.cancel() }
                    
                    if let characteristics = resp.characteristics {
                        continuation.resume(returning: .success(characteristics))
                    } else {
                        continuation.resume(returning: .failure(.init(wrapping: resp.error)))
                    }
                }
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    
    public static func discoverDescriptors(
        forCharacteristic characteristic: any CharacteristicProtocol,
        onPeripheral peripheral: any PeripheralProtocol
    ) async -> Result<[any DescriptorProtocol], DiscoveryTaskFailure> {
        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = peripheral.didDiscoverDescriptorsForCharacteristic
                .sink { resp in
                    guard resp.characteristic.uuid == characteristic.uuid else { return }
                    defer { cancellable?.cancel() }
                    
                    if let descriptors = resp.descriptors {
                        continuation.resume(returning: .success(descriptors))
                    } else {
                        continuation.resume(returning: .failure(.init(wrapping: resp.error)))
                    }
                }
            
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
}
