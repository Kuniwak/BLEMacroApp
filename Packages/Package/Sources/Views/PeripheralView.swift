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
    @ObservedObject private var peripheralBinding: ViewBinding<PeripheralModelState, AnyPeripheralModel>
    @ObservedObject private var distanceBinding: ViewBinding<PeripheralDistanceState, AnyPeripheralDistanceModel>
    @ObservedObject private var iBeaconBinding: ViewBinding<IBeaconState, AnyIBeaconModel>
    private let peripheralModel: any PeripheralModelProtocol
    private let peripheralLogger: PeripheralModelLogger
    private let distanceModel: any PeripheralDistanceModelProtocol
    private let distanceLogger: PeripheralDistanceModelLogger
    private let iBeaconModel: any IBeaconModelProtocol
    private let iBeaconLogger: IBeaconModelLogger
    private let deps: DependencyBag
    @State private var isAlertPresent: Bool = false
    @State private var environmentalFactor: Int = 20
    @State private var environmentalFactorError: Bool = false
    
    
    public init(
        observing peripheralModel: any PeripheralModelProtocol,
        observing distanceModel: any PeripheralDistanceModelProtocol,
        observing iBeaconModel: any IBeaconModelProtocol,
        holding deps: DependencyBag
    ) {
        self.peripheralBinding = ViewBinding(source: peripheralModel.eraseToAny())
        self.peripheralModel = peripheralModel
        self.peripheralLogger = PeripheralModelLogger(observing: peripheralModel, loggingBy: deps.logger)
        self.distanceBinding = ViewBinding(source: distanceModel.eraseToAny())
        self.distanceModel = distanceModel
        self.distanceLogger = PeripheralDistanceModelLogger(observing: distanceModel, loggingBy: deps.logger)
        self.iBeaconBinding = ViewBinding(source: iBeaconModel.eraseToAny())
        self.iBeaconModel = iBeaconModel
        self.iBeaconLogger = IBeaconModelLogger(observing: iBeaconModel, loggingBy: deps.logger)
        self.deps = deps
    }
    
    
    public var body: some View {
        Form {
            Section(header: Text("Properties")) {
                LabeledContent("Name") {
                    ScrollableText(name)
                }
                
                LabeledContent("UUID") {
                    ScrollableText(peripheralBinding.state.uuid.uuidString)
                }
                
                LabeledContent("Manufacturer") {
                    switch peripheralBinding.state.manufacturerData {
                    case .none:
                        Text("No Manufacturer Data")
                    case .some(.knownName(let name, let data)):
                        ScrollableText("\(name) \(HexEncoding.upper.encode(data: data))")
                    case .some(.data(let data)):
                        ScrollableText(HexEncoding.upper.encode(data: data))
                    }
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
            
            if case .success(let iBeacon) = iBeaconBinding.state {
                Section(header: Text("iBeacon")) {
                    LabeledContent("Proximity UUID") {
                        ScrollableText(iBeacon.proximityUUID.uuidString)
                    }
                    
                    LabeledContent("Major") {
                        Text(iBeacon.major.description)
                    }
                    
                    LabeledContent("Minor") {
                        Text(iBeacon.minor.description)
                    }
                    
                    LabeledContent("Measured Power") {
                        Text(String(format: "%d dBm", iBeacon.measuredPower))
                    }
                }
            }
            
            if let distance = distanceBinding.state.distance {
                Section(header: Text("Distance")) {
                    LabeledContent("Est. Distance") {
                        Text(String(format: "%.1f m", distance))
                    }
                    
                    LabeledContent("Env. Factor") {
                        Stepper(
                            value: $environmentalFactor,
                            in: 0...40,
                            step: 1
                        ) {
                            Text(String(format: "%.1f", Double(environmentalFactor) / 10.0))
                        }
                        .onChange(of: environmentalFactor) { newValue, oldValue in
                            distanceModel.update(environmentalFactorTo: Double(newValue) / 10.0)
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

            Section(header: Text("Characteristics")) {
                switch peripheralBinding.state.connection {
                case .notConnectable:
                    HStack {
                        Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                            .foregroundStyle(Color(.error))
                        Text("Not Connectable")
                            .foregroundStyle(Color(.error))
                    }
                case .connected, .connecting, .connectionFailed, .disconnected, .disconnecting:
                    if let services = peripheralBinding.state.discovery.values {
                        if services.isEmpty {
                            Text("No Services")
                                .foregroundStyle(Color(.weak))
                        } else {
                            ForEach(services) { service in
                                NavigationLink(destination: characteristicsView(for: service)) {
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
                                peripheralModel.discover()
                            }
                        }
                    }
                }
            }
        }
        .onAppear() {
            peripheralModel.discover()
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
    
    
    private func characteristicsView(for service: any ServiceModelProtocol) -> some View {
        ServiceView(
            observing: service,
            holding: deps
        )
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            if peripheralBinding.state.connection.canConnect {
                Button("Connect") {
                    peripheralModel.connect()
                }
            } else if peripheralBinding.state.connection.isConnected {
                Button("Disconnect") {
                    peripheralModel.disconnect()
                }
            } else {
                ProgressView()
            }
        }
    }
}


fileprivate struct PreviewEntry {
    public let peripheral: PeripheralModelState
    public let distance: PeripheralDistanceState
    public let iBeacon: IBeaconState
    
    public init(
        peripheral: PeripheralModelState,
        distance: PeripheralDistanceState,
        iBeacon: IBeaconState
    ) {
        self.peripheral = peripheral
        self.distance = distance
        self.iBeacon = iBeacon
    }
}


fileprivate func stubsForPreview() -> [Previewable<(peripheral: AnyPeripheralModel, distance: AnyPeripheralDistanceModel, iBeacon: AnyIBeaconModel)>] {
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
    
    let iBeacons: [IBeaconData] = [
        .init(
            type: .proximity,
            proximityUUID: StubUUID.one,
            major: IBeaconRegion(0x01, 0x23),
            minor: IBeaconRegion(0x45, 0x67),
            measuredPower: -50
        ),
    ]
    
    let distances: [PeripheralDistanceState] = [
        .init(distance: nil, environmentalFactor: 2.0),
        .init(distance: 123, environmentalFactor: 2.0),
    ]
    
    let states1: [PreviewEntry] = discovery.map { discovery in
        .init(
            peripheral: .makeSuccessfulStub(discovery: discovery),
            distance: .makeStub(),
            iBeacon: .failure(.init("TEST"))
        )
    }
    
    let states2: [PreviewEntry] = names.map { name in
        .init(
            peripheral: .makeSuccessfulStub(name: name),
            distance: .makeStub(),
            iBeacon: .failure(.init("TEST"))
        )
    }
    
    let states3: [PreviewEntry] = manufacturers.map { manufacturer in
        .init(
            peripheral: .makeSuccessfulStub(manufacturerData: manufacturer),
            distance: .makeStub(),
            iBeacon: .failure(.init("TEST"))
        )
    }

    let states4: [PreviewEntry] = adData.map { adData in
        .init(
            peripheral: .makeSuccessfulStub(advertisementData: adData),
            distance: .makeStub(),
            iBeacon: .failure(.init("TEST"))
        )
    }

    let states5: [PreviewEntry] = iBeacons.map { iBeacon in
        .init(
            peripheral: .makeSuccessfulStub(),
            distance: .makeSuccessfulStub(),
            iBeacon: .success(iBeacon)
        )
    }

    let states6: [PreviewEntry] = distances.map { distance in
        .init(
            peripheral: .makeSuccessfulStub(),
            distance: distance,
            iBeacon: .failure(.init("TEST"))
        )
    }
    
    return (states1 + states2 + states3 + states4 + states5 + states6)
        .map { state in
            return Previewable(
                (
                    peripheral: StubPeripheralModel(state: state.peripheral).eraseToAny(),
                    distance: StubPeripheralDistanceModel(startsWith: state.distance).eraseToAny(),
                    iBeacon: StubIBeaconModel(state: state.iBeacon).eraseToAny()
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
                    observing: wrapper.value.iBeacon,
                    holding: .makeStub()
                )
            }
            .previewDisplayName(wrapper.description)
        }
    }
}
