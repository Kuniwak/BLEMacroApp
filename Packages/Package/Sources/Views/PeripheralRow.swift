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
    @ObservedObject private var projected: StateProjection<PeripheralModelState>
    
    
    public init(observing model: any PeripheralModelProtocol) {
        self.projected = StateProjection.project(stateMachine: model)
    }

    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                switch projected.state.name {
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
                RSSIView(rssi: projected.state.rssi)
            }
            Text(projected.state.uuid.uuidString)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .foregroundStyle(Color(.weak))
            switch projected.state.manufacturerData {
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


private func stubsForPreview() -> [Previewable<AnyPeripheralModel>] {
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
        .knownName("Example Inc.", Data([0x00, 0x00])),
        .data(Data([0x00, 0x00])),
    ]
    let connection: [ConnectionModelState] = [
        .disconnected,
        .connecting,
        .connectionFailed(.init(description: "TEST")),
        .connected,
        .disconnecting,
    ]
    let state1: [PeripheralModelState] = rssiValues
        .map { rssi in .makeStub(rssi: rssi) }
    let state2: [PeripheralModelState] = names
        .map { name in .makeStub(name: name) }
    let state3: [PeripheralModelState] = manufacturerData
        .map { manufacturerData in .makeStub(manufacturerData: manufacturerData) }
    let state4: [PeripheralModelState] = connection
        .map { connection in .makeStub(connection: connection) }
    return (state1 + state2 + state3 + state4).map { state in
        Previewable(
            StubPeripheralModel(state: state).eraseToAny(),
            describing: state.description
        )
    }
}


#Preview("NavigationLink") {
    NavigationView {
        List(stubsForPreview()) { wrapper in
            NavigationLink(destination: Text("TODO")) {
                PeripheralRow(observing: wrapper.value)
            }
        }
    }
}


#Preview("No NavigationLink") {
    List(stubsForPreview()) { wrapper in
        PeripheralRow(observing: wrapper.value )
    }
}
