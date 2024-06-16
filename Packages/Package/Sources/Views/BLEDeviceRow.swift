import Foundation
import Combine
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
                        Text(name).font(.headline)
                    } else {
                        Text("(no name)").foregroundStyle(.primary)
                    }
                case .failure(let error):
                    Text("E: \(error.description)")
                        .font(.headline)
                        .foregroundColor(Color(.error))
                }
                Spacer()
                RSSIView(rssi: model.state.rssi)
            }
            Text(model.uuid.uuidString)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .foregroundColor(Color(.weak))
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
            .eraseToAny()
        }
    
    List(models) { model in
        BLEDeviceRow(model: model)
    }
}
