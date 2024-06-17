import SwiftUI
import Logger
import Models
import ModelStubs
import SFSymbol
import ViewExtensions
import PreviewHelper


public struct PeripheralsView: View {
    @ObservedObject private var model: AnyPeripheralSearchModel
    private let logger: any LoggerProtocol
    private let modelLogger: PeripheralSearchModelLogger
    
    
    public init(observing model: any PeripheralSearchModelProtocol, loggingBy logger: any LoggerProtocol) {
        self.model = model.eraseToAny()
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
                        if peripheral.state.discoveryState.canConnect {
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
    
    
    private func servicesView(_ peripheral: any PeripheralModelProtocol) -> some View {
        let model = self.model
        return ServicesView(observing: peripheral, loggingBy: logger)
            .onAppear() {
                model.stopScan()
                peripheral.discoverServices()
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
                PeripheralSearchModelState(discoveryState: $0, searchQuery: "Example"),
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
