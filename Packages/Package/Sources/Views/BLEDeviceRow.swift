import Foundation
import SwiftUI
import CoreBluetooth
import CoreBluetoothTestable
import CoreBluetoothStub
import Models
import ModelStubs
import PreviewHelper


public struct BLEDeviceRow: View {
    private let model: any PeripheralModelProtocol
    
    
    public init(_ model: any PeripheralModelProtocol) {
        self.model = model
    }
    
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch model.state.name {
            case .success(let name):
                if let name {
                    Text(name).font(.headline)
                } else {
                    Text("(no name)").font(.headline).foregroundStyle(.gray)
                }
            case .failure(let error):
                Text("\(error)")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
            HStack {
                Text(model.uuid.uuidString)
                    .font(.footnote)
                    .foregroundStyle(.gray)
                Spacer()
                RSSIView(rssi: model.state.rssi)
            }
        }
        .padding(8)
    }
}


#Preview {
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
    let manufacturerNames: [Result<String?, PeripheralModelFailure>] = [
        .success("Manufacturer Name"),
        .success(nil),
        .failure(.init(description: "TEST")),
    ]
    let models = cartesianProduct4(rssiValues, names, [true, false], manufacturerNames)
        .map { rssi, name, isConnectable, manufacturerName in
            StubPeripheralModel(state: .makeStub(
                discoveryState: .makeStub(),
                rssi: rssi,
                name: name,
                isConnectable: isConnectable,
                manufacturerName: manufacturerName
            ))
        }
    List(models) { model in
        BLEDeviceRow(model)
    }
}

