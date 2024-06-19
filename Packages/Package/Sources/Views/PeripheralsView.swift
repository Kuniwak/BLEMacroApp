import SwiftUI
import Logger
import Models
import ModelStubs
import SFSymbol
import ViewExtensions
import PreviewHelper


public struct PeripheralsView: View {
    @ObservedObject private var projection: StateProjection<PeripheralSearchModelState>
    private let model: any PeripheralSearchModelProtocol
    private let logger: any LoggerProtocol
    private let projectionLogger: PeripheralSearchModelLogger
    
    
    public init(observing projection: any PeripheralSearchModelProtocol, loggingBy logger: any LoggerProtocol) {
        self.projection = StateProjection(projecting: projection)
        self.model = projection
        self.logger = logger
        self.projectionLogger = PeripheralSearchModelLogger(
            observing: projection,
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
            switch projection.state.discovery {
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
                    Button("Scan") { Task { await model.startScan() } }
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
                        if peripheral.state.connection.canConnect {
                            NavigationLink(destination: servicesView(peripheral)) {
                                PeripheralRow(observing: peripheral)
                            }
                        } else {
                            PeripheralRow(observing: peripheral)
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
            text: ConcurrentValueSubjectBinding(model.searchQuery)
                .mapBind(\.rawValue, SearchQuery.init(rawValue:)),
            prompt: "Name or UUID or Manufacturer Name"
        )
    }
    
    
    private var trailingNavigationBarItem: some View {
        HStack {
            if projection.state.discovery.isScanning {
                ProgressView()
                Button("Stop", action: { Task { await model.stopScan() } })
                    .disabled(!projection.state.discovery.canStopScan)
            } else {
                Button("Scan", action: { Task { await model.startScan() } })
                    .disabled(!projection.state.discovery.canStartScan)
            }
        }
    }
    
    
    private func servicesView(_ peripheral: any PeripheralModelProtocol) -> some View {
        let model = self.model
        return ServicesView(observing: peripheral, loggingBy: logger)
            .onAppear() {
                model.stopScan()
                peripheral.discover()
            }
            .onDisappear() {
                peripheral.disconnect()
            }
    }
}


internal struct PeripheralsView_Previews: PreviewProvider {
    internal static var previews: some View {
        let discoveryStates: [PeripheralDiscoveryModelState] = [
            .idle,
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
                describing: $0.description
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
