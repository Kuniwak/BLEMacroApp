import SwiftUI
import Logger
import Models
import ModelStubs
import SFSymbol
import ViewFoundation
import PreviewHelper


public struct PeripheralsView: View {
    @ObservedObject private var binding: ViewBinding<PeripheralSearchModelState, AnyPeripheralSearchModel>
    @State var selectedPeripheral: (any PeripheralModelProtocol)? = nil
    private let logger: any LoggerProtocol
    private let modelLogger: PeripheralSearchModelLogger
    
    
    public init(observing model: any PeripheralSearchModelProtocol, loggingBy logger: any LoggerProtocol) {
        self.binding = ViewBinding(source: model.eraseToAny())
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
                    Button("Scan") { Task { await binding.source.startScan() } }
                        .foregroundStyle(.tint)
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
                        NavigationLink(destination: servicesView(peripheral)) {
                            PeripheralRow(observing: peripheral)
                        }.disabled(!peripheral.state.connection.canConnect)
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
            text: ProjectedValueSubjectBinding(binding.source.searchQuery)
                .mapBind(\.rawValue, SearchQuery.init(rawValue:)),
            prompt: "Name or UUID or Manufacturer Name"
        )
        .onAppear {
            Task {
                await self.selectedPeripheral?.disconnect()
                self.selectedPeripheral = nil
            }
        }
    }
    
    
    private func servicesView(_ peripheral: any PeripheralModelProtocol) -> some View {
        return ServicesView(observing: peripheral, loggingBy: logger)
            .onAppear {
                Task {
                    self.selectedPeripheral = peripheral
                    await self.binding.source.stopScan()
                    await peripheral.discover()
                }
            }
    }

    
    private var trailingNavigationBarItem: some View {
        HStack {
            if binding.state.discovery.isScanning {
                ProgressView()
                Button("Stop", action: { Task { await binding.source.stopScan() } })
                    .disabled(!binding.state.discovery.canStopScan)
            } else {
                Button("Scan", action: { Task { await binding.source.startScan() } })
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
            .discovering([]),
            .discovering([
                StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
                StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
            ]),
            .discovered([]),
            .discovered([
                StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
                StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
            ]),
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
                    PeripheralsView(
                        observing: StubPeripheralSearchModel(state: wrapper.value).eraseToAny(),
                        loggingBy: NullLogger()
                    )
                }
                .previewDisplayName(wrapper.description)
            }
        }
    }
}
