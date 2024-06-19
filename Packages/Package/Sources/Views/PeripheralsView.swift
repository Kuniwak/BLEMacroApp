import SwiftUI
import Logger
import Models
import ModelStubs
import SFSymbol
import ViewFoundation
import PreviewHelper


public struct PeripheralsView: View {
    @ObservedObject private var binding: ViewBinding<PeripheralSearchModelState, AnyPeripheralSearchModel>
    private let logger: any LoggerProtocol
    private let projectionLogger: PeripheralSearchModelLogger
    
    
    public init(observing model: any PeripheralSearchModelProtocol, loggingBy logger: any LoggerProtocol) {
        self.binding = ViewBinding(source: model.eraseToAny())
        self.logger = logger
        self.projectionLogger = PeripheralSearchModelLogger(
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
            case .idle, .discovering(.none):
                HStack {
                    Spacer()
                    ProgressView()
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
            case .discovering(.some(let peripherals)), .discovered(let peripherals):
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
            text: ProjectedValueSubjectBinding(binding.source.searchQuery)
                .mapBind(\.rawValue, SearchQuery.init(rawValue:)),
            prompt: "Name or UUID or Manufacturer Name"
        )
    }
    
    
    private func servicesView(_ peripheral: any PeripheralModelProtocol) -> some View {
        let model = self.binding.source
        return ServicesView(observing: peripheral, loggingBy: logger)
            .onAppear() {
                Task { await model.stopScan() }
                Task { await peripheral.discover() }
            }
            .onDisappear() {
                Task { await peripheral.disconnect() }
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
