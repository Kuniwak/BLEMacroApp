import SwiftUI
import CoreBluetoothStub
import Logger
import Models
import ModelStubs
import PreviewHelper
import ViewFoundation
import SFSymbol


public struct ServicesView: View {
    @ObservedObject private var binding: ViewBinding<PeripheralModelState, AnyPeripheralModel>
    private let model: any PeripheralModelProtocol
    private let deps: DependencyBag
    private let modelLogger: PeripheralModelLogger
    @State private var isAlertPresent: Bool = false
    
    
    public init(observing model: any PeripheralModelProtocol, holding deps: DependencyBag) {
        self.binding = ViewBinding(source: model.eraseToAny())
        self.model = model
        self.modelLogger = PeripheralModelLogger(observing: model, loggingBy: deps.logger)
        self.deps = deps
    }
    
    
    public var body: some View {
        List {
            switch binding.state.connection {
            case .notConnectable:
                HStack {
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                        .foregroundStyle(Color(.error))
                    Text("Not Connectable")
                        .foregroundStyle(Color(.error))
                }
            case .connected, .connecting, .connectionFailed, .disconnected, .disconnecting:
                if let services = binding.state.discovery.values {
                    if services.isEmpty {
                        Text("No Services")
                            .foregroundStyle(Color(.weak))
                    } else {
                        ForEach(services) { service in
                            NavigationLink(destination: characteristicsView(for: service)) {
                                ServiceRow(observing: service)
                            }
                            .disabled(!model.state.connection.canConnect && !model.state.connection.isConnected)
                        }
                    }
                } else if binding.state.discovery.isDiscovering {
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
                            model.discover()
                        }
                    }
                }
            }
        }
        .onAppear() {
            model.discover()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Services")
                        .font(.headline)
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                trailingNavigationBarItem
            }
        }
    }
    
    
    private var name: String {
        switch binding.state.name {
        case .success(.some(let name)):
            return name
        case .success(.none):
            return model.state.uuid.uuidString
        case .failure(let error):
            return "E: \(error)"
        }
    }
    
    private func characteristicsView(for service: any ServiceModelProtocol) -> some View {
        CharacteristicsView(
            observing: service,
            holding: deps
        )
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            if binding.state.connection.canConnect {
                Button("Connect") {
                    model.connect()
                }
            } else if binding.state.connection.isConnected {
                Button("Disconnect") {
                    model.disconnect()
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
        .discovered([]),
    ]
    
    let names: [Result<String?, PeripheralModelFailure>] = [
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
            name: name,
            rssi: .success(-50),
            manufacturerData: nil,
            connection: .connected,
            discovery: .discovered([
                StubServiceModel(state: .makeSuccessfulStub()).eraseToAny(),
                StubServiceModel(state: .makeSuccessfulStub()).eraseToAny(),
            ])
        )
    }
    
    return (states1 + states2)
        .map { state in
            return Previewable(
                StubPeripheralModel(state: state).eraseToAny(),
                describing: "\(state.debugDescription)"
            )
        }
}


internal struct ServicesView_Previews: PreviewProvider {
    internal static var previews: some View {
        ForEach(stubsForPreview()) { wrapper in
            NavigationStack {
                ServicesView(
                    observing: wrapper.value,
                    holding: .makeStub()
                )
            }
            .previewDisplayName(wrapper.description)
        }
    }
}
