import SwiftUI
import Models
import ModelStubs
import SFSymbol
import ViewExtensions


public struct BLEDevicesView: View {
    @ObservedObject private var model: AnyPeripheralSearchModel
    
    
    public init(model: AnyPeripheralSearchModel) {
        self.model = model
    }
    
    
    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Discover")
                .navigationBarItems(trailing: trailingNavigationBarItem)
        }
    }
    
    
    private var content: some View {
        List {
            switch model.state.discoveryState {
            case .idle:
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            case .ready:
                HStack {
                    Spacer()
                    Text("Not Scanning.").foregroundStyle(Color(.weak))
                    Button("Scan", action: model.startScan).foregroundStyle(.tint)
                    Spacer()
                }
            case .discovering(let peripherals), .discovered(let peripherals):
                if peripherals.isEmpty {
                    HStack {
                        Spacer()
                        Text("No devices found")
                        Spacer()
                    }
                    .foregroundStyle(Color(.weak))
                } else {
                    ForEach(peripherals) { peripheral in
                        NavigationLink(destination: Text("TODO")) {
                            BLEDeviceRow(model: peripheral)
                        }
                    }
                }
            case .discoveryFailed(.unspecified(let error)):
                HStack {
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                    Text(error)
                }
                .foregroundStyle(Color(.error))
            case .discoveryFailed(.unauthorized):
                HStack {
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                    Text("Bluetooth is unauthorized")
                }
                .foregroundStyle(Color(.weak))
            case .discoveryFailed(.powerOff):
                HStack {
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                    Text("Bluetooth is powered off")
                }
                .foregroundStyle(Color(.weak))
            case .discoveryFailed(.unsupported):
                HStack {
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                    Text("Bluetooth is unsupported")
                }
                .foregroundStyle(Color(.weak))
            }
        }
        .searchable(
            text: model.searchQuery.binding(),
            prompt: "Name or UUID or Manufacturer Name"
        )
    }
    
    
    private var trailingNavigationBarItem: some View {
        HStack {
            if model.state.discoveryState.isScanning {
                ProgressView()
                Button("Stop", action: model.stopScan)
                    .disabled(!model.state.discoveryState.canStopScan)
            } else {
                Button("Scan", action: model.startScan)
                    .disabled(!model.state.discoveryState.canStartScan)
            }
        }
    }
}

#Preview("Idle") {
    BLEDevicesView(model: StubPeripheralSearchModel(
        state: .makeStub(discoveryState: .idle)
    ).eraseToAny())
}

#Preview("Ready") {
    BLEDevicesView(model: StubPeripheralSearchModel(
        state: .makeStub(discoveryState: .ready)
    ).eraseToAny())
}

#Preview("Discovering (empty)") {
    BLEDevicesView(model: StubPeripheralSearchModel(
        state: .makeStub(discoveryState: .discovering([]))
    ).eraseToAny())
}

#Preview("Discovering (not empty)") {
    BLEDevicesView(model: StubPeripheralSearchModel(
        state: .makeStub(discoveryState: .discovering([
            StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
            StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
        ]))
    ).eraseToAny())
}

#Preview("Discovered") {
    BLEDevicesView(model: StubPeripheralSearchModel(
        state: .makeStub(discoveryState: .discovered([
            StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
            StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
        ]))
    ).eraseToAny())
}

#Preview("Unauthorized") {
    BLEDevicesView(model: StubPeripheralSearchModel(
        state: .makeStub(discoveryState: .discoveryFailed(.unauthorized))
    ).eraseToAny())
}

#Preview("Unsupported") {
    BLEDevicesView(model: StubPeripheralSearchModel(
        state: .makeStub(discoveryState: .discoveryFailed(.unsupported))
    ).eraseToAny())
}

#Preview("Unspecified Error") {
    BLEDevicesView(model: StubPeripheralSearchModel(
        state: .makeStub(discoveryState: .discoveryFailed(.unspecified("Something went wrong")))
    ).eraseToAny())
}
