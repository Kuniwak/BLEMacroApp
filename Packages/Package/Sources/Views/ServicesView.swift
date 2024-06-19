import SwiftUI
import CoreBluetoothStub
import Logger
import Models
import ModelStubs
import PreviewHelper
import SFSymbol


public struct ServicesView: View {
    @ObservedObject private var projected: StateProjection<PeripheralModelState>
    private let model: any PeripheralModelProtocol
    private let logger: any LoggerProtocol
    private let modelLogger: PeripheralModelLogger
    @State private var isAlertPresent: Bool = false
    
    
    public init(observing model: any PeripheralModelProtocol, loggingBy logger: any LoggerProtocol) {
        self.projected = StateProjection<PeripheralModelState>.project(stateMachine: model)
        self.model = model
        self.logger = logger
        self.modelLogger = PeripheralModelLogger(observing: model, loggingBy: logger)
    }
    
    
    public var body: some View {
        List {
            switch projected.state.connection {
            case .notConnectable:
                HStack {
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                        .foregroundStyle(Color(.error))
                    Text("Not Connectable")
                        .foregroundStyle(Color(.error))
                }
            case .connected, .connecting, .connectionFailed, .disconnected, .disconnecting:
                if let services = projected.state.discovery.values {
                    ServiceList(observing: services)
                } else if projected.state.discovery.isDiscovering {
                    Text("Discovering...")
                } else {
                    Button("Discover") {
                        Task { await model.discover() }
                    }
                }
            }
        }
        .navigationTitle(name)
        .navigationBarItems(trailing: trailingNavigationBarItem)
    }
    
    
    private var name: String {
        switch projected.state.name {
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
            if projected.state.connection.canConnect {
                Button("Connect") {
                    Task { await model.connect() }
                }
            } else if projected.state.connection.isConnected {
                Button("Disconnect") {
                    Task { await model.disconnect() }
                }
            } else {
                ProgressView()
            }
        }
    }
}


private func stubsForPreview() -> [Previewable<AnyPeripheralModel>] {
    let discovery: [ServiceDiscoveryModelState] = [
        .notDiscoveredYet,
        .discovering(nil),
        .discovered(StateMachineArray([])),
    ]
    
    let names: [Result<String?, ConnectionModelFailure>] = [
        .success(nil),
        .failure(.init(description: "TEST")),
    ]
    
    let states1: [PeripheralModelState] = discovery.map { discovery in
        PeripheralModelState(
            uuid: StubUUID.zero,
            name: .success("Example Device"),
            rssi: .success(-50),
            manufacturerData: nil,
            connection: .connected,
            discovery: discovery
        )
    }
    
    let states2: [PeripheralModelState] = names.map { name in
        PeripheralModelState(
            uuid: StubUUID.zero,
            name: .success("Example Device"),
            rssi: .success(-50),
            manufacturerData: nil,
            connection: .connected,
            discovery: .discovered(StateMachineArray([
                StubServiceModel(state: .makeSuccessfulStub()).eraseToAny(),
                StubServiceModel(state: .makeSuccessfulStub()).eraseToAny(),
            ]))
        )
    }
    
    return (states1 + states2).enumerated()
        .map { pair in
            var state = pair.1
            state.uuid = StubUUID.from(byte: UInt8(pair.0))
            let name: String
            switch state.name {
            case .success(.some(let value)):
                name = value
            case .success(.none):
                name = "nil"
            case .failure(let error):
                name = "\(error)"
            }
            return Previewable(
                StubPeripheralModel(state: state).eraseToAny(),
                describing: "\(state.discovery.description) \(name)"
            )
        }
}


#Preview {
    ForEach(stubsForPreview()) { wrapper in
        NavigationStack {
            ServicesView(
                observing: wrapper.value,
                loggingBy: NullLogger()
            )
        }
        .previewDisplayName(wrapper.description)
    }
}
