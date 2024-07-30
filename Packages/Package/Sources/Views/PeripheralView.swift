import SwiftUI
import CoreBluetooth
import CoreBluetoothStub
import BLEInternal
import Logger
import Catalogs
import Models
import ModelStubs
import PreviewHelper
import ViewFoundation
import SFSymbol


public struct PeripheralView: View {
    @StateObject private var peripheralBinding: ViewBinding<PeripheralModelState, AnyAutoRefreshedPeripheralModel>
    @StateObject private var distanceBinding: ViewBinding<PeripheralDistanceState, AnyPeripheralDistanceModel>
    private let peripheralLogger: PeripheralModelLogger
    private let distanceLogger: PeripheralDistanceModelLogger
    private let deps: PeripheralDependencyBag
    @State private var isAlertPresent: Bool = false
    @State private var environmentalFactor: Int = 20
    @State private var environmentalFactorError: Bool = false
    @State private var txPower: Int
    
    
    public init(
        observing peripheralModel: any AutoRefreshedPeripheralModelProtocol,
        observing distanceModel: any PeripheralDistanceModelProtocol,
        holding deps: PeripheralDependencyBag
    ) {
        self._peripheralBinding = StateObject(wrappedValue: ViewBinding(source: peripheralModel.eraseToAny()))
        self.peripheralLogger = PeripheralModelLogger(observing: peripheralModel, loggingBy: deps.logger)
        self._distanceBinding = StateObject(wrappedValue: ViewBinding(source: distanceModel.eraseToAny()))
        self.distanceLogger = PeripheralDistanceModelLogger(observing: distanceModel, loggingBy: deps.logger)
        self.txPower = Int(distanceModel.state.txPower)
        self.deps = deps
    }
    
    
    public var body: some View {
        Form {
            Section(header: Text("Peripheral")) {
                LabeledContent("Name") {
                    ScrollableText(name)
                }
                
                LabeledContent("UUID") {
                    ScrollableText(peripheralBinding.state.uuid.uuidString)
                }
                
                LabeledContent("RSSI") {
                    switch peripheralBinding.state.rssi {
                    case .failure(let error):
                        ScrollableText("E: \(error)")
                            .foregroundStyle(Color(.error))
                    case .success(let rssi):
                        HStack {
                            Text(String(format: "%.1f dBm", rssi.doubleValue))
                            RSSIView(rssi: .success(rssi))
                        }
                    }
                }
                
                if peripheralBinding.state.connection.canConnect {
                    Button("Connect to Refresh RSSI") {
                        peripheralBinding.source.connect()
                    }
                }
            }
            
            Section(header: Text("Manifacturer")) {
                switch peripheralBinding.state.manufacturerData {
                case .none:
                    LabeledContent("Manufacturer Data") {
                        Text("No Data")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)

                        Text(
                            """
                            For some unknown reason, CoreBluetooth cannot get manufacturer data even though the device provides it.
                            """
                        )
                        .font(.caption)
                    }
                    .foregroundStyle(Color(.weak))

                case .some(.knownName(let name, let data)):
                    LabeledContent("Manufacturer Name") {
                        ScrollableText(name.description)
                    }
                    LabeledContent("Manufacturer UUID") {
                        Text(String(format: "%02X%02X", name.byte1, name.byte2))
                    }
                    LabeledContent("Manufacturer Data") {
                        ScrollableText(HexEncoding.upper.encode(data: data))
                    }
                    
                case .some(.data(let data)):
                    LabeledContent("Manufacturer Name") {
                        Text("Unknown")
                    }
                    LabeledContent("Manufacturer Data") {
                        ScrollableText(HexEncoding.upper.encode(data: data))
                    }
                }
            }
            
            Section(header: Text("Advertisement Data")) {
                if peripheralBinding.state.advertisementData.isEmpty {
                    Text("No Advertisement Data")
                        .foregroundStyle(Color(.weak))
                } else {
                    let sorted = peripheralBinding.state.advertisementData
                        .sorted(by: { $0.key < $1.key })
                    ForEach(sorted, id: \.key) { key, value in
                        LabeledContent(key.replacingOccurrences(of: "kCBAdvData", with: "")) {
                            ScrollableText("\(value)")
                        }
                    }
                }
            }
            
            if let distance = distanceBinding.state.distance {
                Section(header: Text("Distance")) {
                    LabeledContent("Est. Distance") {
                        Text(String(format: "%.1f m", distance))
                    }
                    
                    LabeledContent("TX Power") {
                        Stepper(value: $txPower, in: -100...100, step: 1) {
                            Text(String(format: "%d dBm", txPower))
                        }
                        .onChange(of: txPower) { _, newValue in
                            distanceBinding.source.update(txPowerTo: Double(newValue))
                        }
                    }
                    
                    Button("Assume TX Power as -50 dBm") {
                        txPower = -50
                        distanceBinding.source.update(environmentalFactorTo: Double(txPower))
                    }
                    
                    LabeledContent("Env. Factor") {
                        Stepper(value: $environmentalFactor, in: 0...40, step: 1) {
                            Text(String(format: "%.1f", Double(environmentalFactor) / 10.0))
                        }
                        .onChange(of: environmentalFactor) { _, newValue in
                            distanceBinding.source.update(environmentalFactorTo: Double(newValue) / 10.0)
                        }
                    }
                    
                    Text(
                         """
                         RSSI = txPower - 10 * envFactor * log10(distance)
                         If radio wave environment is ideal, envFactor = 2.0.
                         If the environment is reflexive, envFactor is > 2.0.
                         If the environment is absorptive, envFactor is < 2.0.
                         """
                    )
                    .foregroundStyle(Color(.weak))
                    .font(.caption)
                }
            }

            Section(header: Text("Services")) {
                switch peripheralBinding.state.connection {
                case .notConnectable:
                    HStack {
                        Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                            .foregroundStyle(Color(.weak))
                        Text("Not Connectable")
                            .foregroundStyle(Color(.weak))
                    }
                case .connected, .connecting, .connectionFailed, .disconnected, .disconnecting:
                    if let services = peripheralBinding.state.discovery.values {
                        if services.isEmpty {
                            Text("No Services")
                                .foregroundStyle(Color(.weak))
                        } else {
                            ForEach(services) { service in
                                NavigationLink(destination: ServiceView(observing: service, holding: deps)) {
                                    ServiceRow(observing: service)
                                }
                                .disabled(!peripheralBinding.state.connection.canConnect && !peripheralBinding.state.connection.isConnected)
                            }
                        }
                    } else if peripheralBinding.state.discovery.isDiscovering {
                        HStack(spacing: 10) {
                            Spacer()
                            ProgressView()
                            Text("Discovering...")
                                .foregroundStyle(Color(.weak))
                            Spacer()
                        }
                    } else {
                        HStack {
                            Text("Not Discovering.")
                                .foregroundStyle(Color(.weak))
                            Button("Start") {
                                peripheralBinding.source.discover()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            peripheralBinding.source.setAutoRefresh(true)
            peripheralBinding.source.connect()
            peripheralBinding.source.discover()
        }
        .onDisappear {
            peripheralBinding.source.setAutoRefresh(false)
        }
        .navigationTitle("Peripheral")
        .navigationBarItems(trailing: trailingNavigationBarItem)
    }
    
    
    private var name: String {
        switch peripheralBinding.state.name {
        case .success(.some(let name)):
            return name
        case .success(.none):
            return "(no name)"
        case .failure(let error):
            return "E: \(error)"
        }
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            switch peripheralBinding.state.connection {
            case .connecting, .disconnecting:
                ProgressView()
            case .connected:
                Button("Disconnect") {
                    peripheralBinding.source.disconnect()
                }
            case .notConnectable, .disconnected, .connectionFailed:
                Button("Connect") {
                    peripheralBinding.source.connect()
                }
                .disabled(!peripheralBinding.state.connection.canConnect)
            }
        }
    }
}


fileprivate struct PreviewEntry {
    public let peripheral: PeripheralModelState
    public let distance: PeripheralDistanceState
    
    public init(
        peripheral: PeripheralModelState,
        distance: PeripheralDistanceState
    ) {
        self.peripheral = peripheral
        self.distance = distance
    }
}


fileprivate func stubsForPreview() -> [Previewable<(peripheral: AnyAutoRefreshedPeripheralModel, distance: AnyPeripheralDistanceModel)>] {
    let discovery: [ServiceDiscoveryModelState] = [
        .notDiscoveredYet,
        .discovering(nil),
        .discovered([]),
    ]
    
    let names: [Result<String?, PeripheralModelFailure>] = [
        .success(nil),
    ]
    
    let manufacturers: [ManufacturerData] = [
        .knownName(ManufacturerName(name: "Example Manufacturer", 0x01, 0x23), Data([0x01, 0x23, 0x45])),
    ]
    
    let adData: [[String: Any]] = [
        [
            CBAdvertisementDataLocalNameKey: "Example Device",
            CBAdvertisementDataManufacturerDataKey: Data(),
            CBAdvertisementDataIsConnectable: true,
            CBAdvertisementDataTxPowerLevelKey: 0,
        ],
    ]
    
    let distances: [PeripheralDistanceState] = [
        .init(distance: nil, environmentalFactor: 2.0, txPower: -50),
        .init(distance: 123, environmentalFactor: 2.0, txPower: -59),
    ]
    
    let states1: [PreviewEntry] = discovery.map { discovery in
        .init(
            peripheral: .makeSuccessfulStub(discovery: discovery),
            distance: .makeStub()
        )
    }
    
    let states2: [PreviewEntry] = names.map { name in
        .init(
            peripheral: .makeSuccessfulStub(name: name),
            distance: .makeStub()
        )
    }
    
    let states3: [PreviewEntry] = manufacturers.map { manufacturer in
        .init(
            peripheral: .makeSuccessfulStub(manufacturerData: manufacturer),
            distance: .makeStub()
        )
    }

    let states4: [PreviewEntry] = adData.map { adData in
        .init(
            peripheral: .makeSuccessfulStub(advertisementData: adData),
            distance: .makeStub()
        )
    }

    let states5: [PreviewEntry] = distances.map { distance in
        .init(
            peripheral: .makeSuccessfulStub(),
            distance: distance
        )
    }
    
    return (states1 + states2 + states3 + states4 + states5)
        .map { state in
            return Previewable(
                (
                    peripheral: StubAutoRefreshedPeripheralModel(state: state.peripheral).eraseToAny(),
                    distance: StubPeripheralDistanceModel(startsWith: state.distance).eraseToAny()
                ),
                describing: "(peripheral: \(state.peripheral.debugDescription), distance: \(state.distance.debugDescription))"
            )
        }
}


internal struct ServicesView_Previews: PreviewProvider {
    internal static var previews: some View {
        ForEach(stubsForPreview()) { wrapper in
            NavigationStack {
                PeripheralView(
                    observing: wrapper.value.peripheral,
                    observing: wrapper.value.distance,
                    holding: .makeStub()
                )
            }
            .previewDisplayName(wrapper.description)
        }
    }
}
