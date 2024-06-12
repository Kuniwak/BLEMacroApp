import SwiftUI
import CoreBluetooth
import CoreBluetoothStub
import Logger
import Models
import ModelStubs
import PreviewHelper
import ViewFoundation
import SFSymbol


public struct CharacteristicsView: View {
    @ObservedObject private var binding: ViewBinding<ServiceModelState, AnyServiceModel>
    private let model: any ServiceModelProtocol
    private let logger: any LoggerProtocol
    private let modelLogger: ServiceModelLogger
    @State private var isAlertPresent: Bool = false
    
    
    public init(observing model: any ServiceModelProtocol, loggingBy logger: any LoggerProtocol) {
        self.binding = ViewBinding(source: model.eraseToAny())
        self.model = model
        self.modelLogger = ServiceModelLogger(observing: model, loggingBy: logger)
        self.logger = logger
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
                if let characteristics = binding.state.discovery.values {
                    if characteristics.isEmpty {
                        Text("No Characteristics")
                            .foregroundStyle(Color(.weak))
                    } else {
                        ForEach(characteristics) { characteristic in
                            NavigationLink(destination: descriptorsView(for: characteristic)) {
                                CharacteristicRow(observing: characteristic)
                            }
                            .disabled(!model.state.connection.isConnected)
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
                        Button("Start Discovery") {
                            Task { await model.discover() }
                        }
                    }
                }
            }
        }
        .onAppear() {
            Task { await model.discover() }
        }
        .navigationTitle(model.state.name ?? model.state.uuid.uuidString)
        .navigationBarItems(trailing: trailingNavigationBarItem)
    }
    
    
    private func descriptorsView(for characteristic: any CharacteristicModelProtocol) -> some View {
        Text("TODO")
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            if binding.state.connection.canConnect {
                Button("Connect") {
                    Task { await model.connect() }
                }
            } else if binding.state.connection.isConnected {
                Button("Disconnect") {
                    Task { await model.disconnect() }
                }
            } else {
                ProgressView()
            }
        }
    }
}


private func stubsForPreview() -> [Previewable<AnyServiceModel>] {
    let names: [String?] = [
        nil,
        "Example"
    ]
    
    
    let discovery: [CharacteristicDiscoveryModelState] = [
        .notDiscoveredYet,
        .discovering(nil),
        .discovered([]),
    ]
    
    let connections: [ConnectionModelState] = [
        .notConnectable,
        .connected,
        .connecting,
        .connectionFailed(.init(description: "TEST")),
        .disconnected,
        .disconnecting,
    ]
    
    let states1: [ServiceModelState] = names.map { name in
        .makeSuccessfulStub(name: name)
    }

    let states2: [ServiceModelState] = discovery.map { discovery in
        .makeSuccessfulStub(discovery: discovery)
    }
    
    let state3: [ServiceModelState] = connections.map { connection in
        .makeSuccessfulStub(connection: connection)
    }
    
    return (states1 + states2 + state3)
        .map { state in
            return Previewable(
                StubServiceModel(state: state).eraseToAny(),
                describing: "\(state.debugDescription)"
            )
        }
}


internal struct CharacteristicsView_Previews: PreviewProvider {
    
    internal static var previews: some View {
        ForEach(stubsForPreview()) { wrapper in
            NavigationStack {
                CharacteristicsView(
                    observing: wrapper.value,
                    loggingBy: NullLogger()
                )
            }
            .previewDisplayName(wrapper.description)
            .previewLayout(.sizeThatFits)
        }
    }
}
