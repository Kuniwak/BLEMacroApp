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
    
    
    public init(observing model: any PeripheralSearchModelProtocol, loggingBy logger: any LoggerProtocol) {
        self.projection = StateProjection.project(stateMachine: model)
        self.model = model
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
            switch projection.state.discovery {
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
                    Button("Scan") { Task { await model.startScan() } }
                        .foregroundStyle(.tint)
                    Spacer()
                }
            case .discovering(.some(let peripherals)), .discovered(let peripherals):
                PeripheralList(
                    projecting: peripherals,
                    stoppingScanningBy: model,
                    loggingBy: logger
                )
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
}


internal struct PeripheralsView_Previews: PreviewProvider {
    internal static var previews: some View {
        let discoveryStates: [PeripheralDiscoveryModelState] = [
            .idle,
            .ready,
            .discovering(StateMachineArray([])),
            .discovering(StateMachineArray([
                StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
                StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
            ])),
            .discovered(StateMachineArray([])),
            .discovered(StateMachineArray([
                StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
                StubPeripheralModel(state: .makeSuccessfulStub()).eraseToAny(),
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
