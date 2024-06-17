import Combine
import CoreBluetooth
import CoreBluetoothTestable
import Catalogs


public struct CharacteristicModelFailure: Error, CustomStringConvertible {
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


extension AttributeDiscoveryModel {
    public static func forCharacteristic(
        characteristic: any CharacteristicProtocol,
        onPeripheral peripheral: any PeripheralProtocol,
        controlledBy peripheralModel: any PeripheralModelProtocol
    ) -> some AttributeDiscoveryModel<AnyDescriptorModel, DescriptorModelFailure> {
        let discoveryModel = DiscoveryModel<AnyDescriptorModel, DescriptorModelFailure>(
            identifiedBy: characteristic.uuid,
            discoveringBy: { peripheral async in
                await withCheckedContinuation { continuation in
                    var cancellable:  AnyCancellable?
                    cancellable = peripheral.didDiscoverDescriptorsForCharacteristic
                        .sink { resp in
                            guard resp.characteristic.uuid == characteristic.uuid else { return }
                            defer { cancellable?.cancel() }
                            
                            if let descriptors = resp.descriptors {
                                let models = descriptors.map {
                                    DescriptorModel(
                                        startsWith: .initialState(fromDescriptorUUID: $0.uuid),
                                        descriptor: $0,
                                        peripheral: peripheral
                                    ).eraseToAny()
                                }
                                continuation.resume(returning: .success(models))
                            } else {
                                continuation.resume(returning: .failure(DescriptorModelFailure(wrapping: resp.error)))
                            }
                        }
                        
                    peripheral.discoverDescriptors(for: characteristic)
                }
            },
            thatTakes: peripheral
        )
        return AttributeDiscoveryModel<AnyDescriptorModel, DescriptorModelFailure>(
            identifiedBy: characteristic.uuid,
            discoveringBy: discoveryModel,
            connectingBy: peripheralModel
        )
    }
}
