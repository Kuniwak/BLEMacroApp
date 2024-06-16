import Foundation
import Combine
import Catalogs
import BLEInternal
import SwiftUI
import CoreBluetooth
import CoreBluetoothTestable
import CoreBluetoothStub
import Models
import ModelStubs
import PreviewHelper


public struct BLEDeviceRow: View {
    @ObservedObject public var model: AnyPeripheralModel
    
    
    public init(model: any PeripheralModelProtocol) {
        self.model = model.eraseToAny()
    }

    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                switch model.state.name {
                case .success(let name):
                    if let name {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(Color(.normal))
                    } else {
                        Text("(no name)")
                            .font(.headline)
                            .foregroundStyle(Color(.weak))
                    }
                case .failure(let error):
                    Text("E: \(error.description)")
                        .font(.headline)
                        .foregroundStyle(Color(.error))
                }
                Spacer()
                RSSIView(rssi: model.state.rssi)
            }
            Text(model.uuid.uuidString)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .foregroundStyle(Color(.weak))
            switch model.state.manufacturerData {
            case .some(.knownName(let manufacturerName, let data)):
                Text("Manufacturer: \(manufacturerName) - \(HexEncoding.upper.encode(data: data))")
                    .font(.footnote)
                    .foregroundStyle(Color(.weak))
            case .some(.data(let data)):
                Text("Manufacturer: \(HexEncoding.upper.encode(data: data))")
                    .font(.footnote)
                    .foregroundStyle(Color(.weak))
            case .none:
                EmptyView()
            }
        }
        .padding(8)
    }
}


#Preview("NavigationLink") {
    let rssiValues: [Result<NSNumber, PeripheralModelFailure>] = [
        .success(NSNumber(value: -50)),
        .success(NSNumber(value: -60)),
        .success(NSNumber(value: -70)),
        .success(NSNumber(value: -80)),
        .failure(.init(description: "TEST")),
    ]
    let names: [Result<String?, PeripheralModelFailure>] = [
        .success("Device Name"),
        .success(nil),
        .failure(.init(description: "TEST")),
    ]
    let manufacturerData: [ManufacturerData?] = [
        nil,
        .knownName("Example Ltd.", Data([0x00, 0x00])),
        .data(Data([0x00, 0x00])),
    ]
    let models = cartesianProduct4(rssiValues, names, [true, false], manufacturerData)
        .map { rssi, name, isConnectable, manufacturerData in
            StubPeripheralModel(state: .makeStub(
                discoveryState: .makeStub(),
                rssi: rssi,
                name: name,
                isConnectable: isConnectable,
                manufacturerData: manufacturerData
            ))
            .eraseToAny()
        }
    
    NavigationView {
        List(models) { model in
            NavigationLink(destination: Text("TODO")) {
                BLEDeviceRow(model: model)
            }
        }
    }
}


#Preview("No NavigationLink") {
    let rssiValues: [Result<NSNumber, PeripheralModelFailure>] = [
        .success(NSNumber(value: -50)),
        .success(NSNumber(value: -60)),
        .success(NSNumber(value: -70)),
        .success(NSNumber(value: -80)),
        .failure(.init(description: "TEST")),
    ]
    let names: [Result<String?, PeripheralModelFailure>] = [
        .success("Device Name"),
        .success(nil),
        .failure(.init(description: "TEST")),
    ]
    let manufacturerData: [ManufacturerData?] = [
        nil,
        .knownName("Manufacturer Name", Data([0x00, 0x00])),
        .data(Data([0x00, 0x00])),
    ]
    let models = cartesianProduct4(rssiValues, names, [true, false], manufacturerData)
        .map { rssi, name, isConnectable, manufacturerData in
            StubPeripheralModel(state: .makeStub(
                discoveryState: .makeStub(),
                rssi: rssi,
                name: name,
                isConnectable: isConnectable,
                manufacturerData: manufacturerData
            ))
            .eraseToAny()
        }
    
    List(models) { model in
        BLEDeviceRow(model: model)
    }
}
