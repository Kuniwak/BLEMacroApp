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
import ViewFoundation
import PreviewHelper


public struct PeripheralRow: View {
    @ObservedObject private var binding: ViewBinding<PeripheralModelState, AnyPeripheralModel>
    
    
    public init(observing model: any PeripheralModelProtocol) {
        self.binding = ViewBinding(source: model.eraseToAny())
    }

    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                switch binding.state.name {
                case .success(let name):
                    if let name {
                        Text(name)
                            .foregroundStyle(Color(.normal))
                    } else {
                        Text("(no name)")
                            .foregroundStyle(Color(.weak))
                    }
                case .failure(let error):
                    Text("E: \(error.description)")
                        .foregroundStyle(Color(.error))
                }
                Spacer()
                RSSIView(rssi: binding.state.rssi)
            }
            Text(binding.state.uuid.uuidString)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .foregroundStyle(Color(.weak))
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
        .knownName(ManufacturerName(name: "Example Inc.", 0x01, 0x23), Data([0x00, 0x00])),
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
        .map { rssi in .makeSuccessfulStub(rssi: rssi) }
    let state2: [PeripheralModelState] = names
        .map { name in .makeSuccessfulStub(name: name) }
    let state3: [PeripheralModelState] = manufacturerData
        .map { manufacturerData in .makeSuccessfulStub(manufacturerData: manufacturerData) }
    let state4: [PeripheralModelState] = connection
        .map { connection in .makeSuccessfulStub(connection: connection) }
    return (state1 + state2 + state3 + state4)
        .map { state in
            Previewable(
                StubPeripheralModel(state: state).eraseToAny(),
                describing: state.description
            )
        }
}


#Preview {
    NavigationView {
        List(stubsForPreview()) { wrapper in
            NavigationLink(destination: Text("TODO")) {
                PeripheralRow(observing: wrapper.value)
            }
        }
    }
}
