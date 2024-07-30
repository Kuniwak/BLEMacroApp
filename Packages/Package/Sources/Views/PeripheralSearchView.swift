import SwiftUI
import CoreBluetoothStub
import Logger
import Models
import ModelStubs
import SFSymbol
import ViewFoundation
import PreviewHelper


public struct PeripheralSearchView: View {
    @StateObject private var binding: ViewBinding<PeripheralSearchModelState, AnyPeripheralSearchModel>
    @State private var searchQuery: String = ""
    @Environment(\.scenePhase) private var scenePhase
    private let logger: any LoggerProtocol
    private let modelLogger: PeripheralSearchModelLogger
    
    
    public init(observing model: any PeripheralSearchModelProtocol, loggingBy logger: any LoggerProtocol) {
        self._binding = StateObject(wrappedValue: ViewBinding(source: model.eraseToAny()))
        self.logger = logger
        self.modelLogger = PeripheralSearchModelLogger(
            observing: model,
            loggingBy: logger
        )
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
            switch binding.state.discovery {
            case .idle:
                HStack(spacing: 10) {
                    Spacer()
                    ProgressView()
                    Text("Waiting BLE Powered On...")
                        .foregroundStyle(Color(.weak))
                    Spacer()
                }
            case .ready:
                HStack {
                    Spacer()
                    Text("Not Scanning.").foregroundStyle(Color(.weak))
                    Button("Scan") { binding.source.startScan() }
                        .foregroundStyle(.tint)
                    Spacer()
                }
            case .discovering(let entries), .discovered(let entries):
               if entries.isEmpty {
                    HStack {
                        Spacer()
                        Text("No devices found")
                        Spacer()
                    }
                    .foregroundStyle(Color(.weak))
                } else {
                    ForEach(entries.ordered) { entry in
                        NavigationLink(destination: peripheralView(entry: entry)) {
                            PeripheralRow(observing: entry.peripheral)
                        }
                    }
                }
            case .discoveryFailed(.unspecified(let error)):
                HStack {
                    Spacer()
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                    Text(error)
                    Spacer()
                }
                .foregroundStyle(Color(.error))
            case .discoveryFailed(.unauthorized):
                HStack {
                    Spacer()
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                    Text("Bluetooth is unauthorized")
                    Spacer()
                }
                .foregroundStyle(Color(.weak))
            case .discoveryFailed(.powerOff):
                HStack {
                    Spacer()
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                    Text("Bluetooth is powered off")
                    Spacer()
                }
                .foregroundStyle(Color(.weak))
            case .discoveryFailed(.unsupported):
                HStack {
                    Spacer()
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                    Text("Bluetooth is unsupported")
                    Spacer()
                }
                .foregroundStyle(Color(.weak))
            }
        }
        .searchable(
            text: $searchQuery,
            prompt: "Name or UUID or Manufacturer Name"
        )
        .onChange(of: searchQuery) { _, newQuery in
            binding.source.updateSearchQuery(to: SearchQuery(rawValue: newQuery))
        }
        .onDisappear { binding.source.stopScan() }
        .onAppear {
            binding.source.startScan()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                binding.source.stopScan()
            default:
                break
            }
        }
    }
    
    
    private func peripheralView(entry: PeripheralEntry) -> some View {
        let deps = DependencyBag(connectionModel: entry.connection, logger: logger)
        return PeripheralView(
            observing: AutoRefreshedPeripheralModel(
                wrapping: entry.peripheral,
                withTimeInterval: 2
            ),
            observing: PeripheralDistanceModel(
                observing: entry.peripheral,
                withEnvironmentalFactor: 2.0
            ),
            holding: deps
        )
    }

    
    private var trailingNavigationBarItem: some View {
        HStack {
            if binding.state.discovery.isScanning {
                ProgressView()
                Button("Stop", action: { binding.source.stopScan() })
                    .disabled(!binding.state.discovery.canStopScan)
            } else {
                Button("Scan", action: { binding.source.startScan() })
                    .disabled(!binding.state.discovery.canStartScan)
            }
        }
    }
}


internal struct PeripheralsView_Previews: PreviewProvider {
    internal static var previews: some View {
        let discoveryStates: [PeripheralDiscoveryModelState] = [
            .idle(requestedDiscovery: false),
            .idle(requestedDiscovery: true),
            .ready,
            .discovering(.empty),
            .discovering(.init(ordered: [
                .init(
                    peripheral: StubPeripheralModel(state: .makeSuccessfulStub(uuid: StubUUID.one)),
                    connection: StubConnectionModel(state: .makeSuccessfulStub())
                ),
                .init(
                    peripheral: StubPeripheralModel(state: .makeSuccessfulStub(uuid: StubUUID.two)),
                    connection: StubConnectionModel(state: .makeSuccessfulStub())
                ),
            ])),
            .discovered(.empty),
            .discovered(.init(ordered: [
                .init(
                    peripheral: StubPeripheralModel(state: .makeSuccessfulStub(uuid: StubUUID.one)),
                    connection: StubConnectionModel(state: .makeSuccessfulStub())
                ),
                .init(
                    peripheral: StubPeripheralModel(state: .makeSuccessfulStub(uuid: StubUUID.two)),
                    connection: StubConnectionModel(state: .makeSuccessfulStub())
                ),
            ])),
            .discoveryFailed(.unsupported),
            .discoveryFailed(.unsupported),
            .discoveryFailed(.unspecified("Something went wrong"))
        ]
        
        let wrappers: [Previewable] = discoveryStates.map {
            Previewable(
                PeripheralSearchModelState(
                    discovery: $0,
                    searchQuery: SearchQuery(rawValue: "Example")
                ),
                describing: $0.debugDescription
            )
        }
        
        Group {
            ForEach(wrappers) { wrapper in
                NavigationStack {
                    PeripheralSearchView(
                        observing: StubPeripheralSearchModel(state: wrapper.value).eraseToAny(),
                        loggingBy: NullLogger()
                    )
                }
                .previewDisplayName(wrapper.description)
            }
        }
    }
}
