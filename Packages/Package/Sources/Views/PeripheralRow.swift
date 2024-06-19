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


public struct PeripheralRow: View {
    @ObservedObject public var projection: StateProjection<PeripheralModelState>
    
    
    public init(observing model: any PeripheralModelProtocol) {
        self.projection = StateProjection(projecting: model)
    }

    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                switch projection.state.name {
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
                RSSIView(rssi: projection.state.rssi)
            }
            Text(projection.state.uuid.uuidString)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .foregroundStyle(Color(.weak))
            switch projection.state.manufacturerData {
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
    let rssiValues: [Result<NSNumber, ConnectionModelFailure>] = [
        .success(NSNumber(value: -50)),
        .success(NSNumber(value: -60)),
        .success(NSNumber(value: -70)),
        .success(NSNumber(value: -80)),
        .failure(.init(description: "TEST")),
    ]
    let names: [Result<String?, ConnectionModelFailure>] = [
        .success("Device Name"),
        .success(nil),
        .failure(.init(description: "TEST")),
    ]
    let manufacturerData: [ManufacturerData?] = [
        nil,
        .knownName("Example Ltd.", Data([0x00, 0x00])),
        .data(Data([0x00, 0x00])),
    ]
    let projections = cartesianProduct4(rssiValues, names, [true, false], manufacturerData)
        .map { rssi, name, isConnectable, manufacturerData in
            StubConnectionModel(state: .makeStub(
                discoveryState: .makeStub(),
                rssi: rssi,
                name: name,
                isConnectable: isConnectable,
                manufacturerData: manufacturerData
            ))
            .eraseToAny()
        }
    
    NavigationView {
        List(projections) { projection in
            NavigationLink(destination: Text("TODO")) {
                PeripheralRow(observing: projection)
            }
        }
    }
}


#Preview("No NavigationLink") {
    let rssiValues: [Result<NSNumber, ConnectionModelFailure>] = [
        .success(NSNumber(value: -50)),
        .success(NSNumber(value: -60)),
        .success(NSNumber(value: -70)),
        .success(NSNumber(value: -80)),
        .failure(.init(description: "TEST")),
    ]
    let names: [Result<String?, ConnectionModelFailure>] = [
        .success("Device Name"),
        .success(nil),
        .failure(.init(description: "TEST")),
    ]
    let manufacturerData: [ManufacturerData?] = [
        nil,
        .knownName("Manufacturer Name", Data([0x00, 0x00])),
        .data(Data([0x00, 0x00])),
    ]
    let projections = cartesianProduct4(rssiValues, names, [true, false], manufacturerData)
        .map { rssi, name, isConnectable, manufacturerData in
            StubConnectionModel(state: .makeStub(
                discoveryState: .makeStub(),
                rssi: rssi,
                name: name,
                isConnectable: isConnectable,
                manufacturerData: manufacturerData
            ))
            .eraseToAny()
        }
    
    List(projections) { projection in
        PeripheralRow(observing: projection)
    }
}
