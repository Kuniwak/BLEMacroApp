import SwiftUI
import CoreBluetooth
import CoreBluetoothStub
import Logger
import Models
import ModelStubs
import PreviewHelper
import ViewFoundation
import SFSymbol


public struct ServiceView: View {
    @ObservedObject private var binding: ViewBinding<ServiceModelState, AnyServiceModel>
    private let model: any ServiceModelProtocol
    private let deps: DependencyBag
    private let modelLogger: ServiceModelLogger
    @State private var isAlertPresent: Bool = false
    
    
    public init(observing model: any ServiceModelProtocol, holding deps: DependencyBag) {
        self.binding = ViewBinding(source: model.eraseToAny())
        self.model = model
        self.modelLogger = ServiceModelLogger(observing: model, loggingBy: deps.logger)
        self.deps = deps
    }
    
    
    public var body: some View {
        Form {
            Section(header: Text("Properties")) {
                LabeledContent("Name") {
                    if let name = binding.state.name {
                        GeometryReader { geometry in
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(name)
                                    .lineLimit(1)
                                    .frame(
                                        minWidth: geometry.size.width,
                                        minHeight: geometry.size.height,
                                        maxHeight: geometry.size.height,
                                        alignment: .trailing
                                    )
                            }
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height,
                                alignment: .trailing
                            )
                        }
                    } else {
                        Text("No Name")
                    }
                }
                
                LabeledContent("UUID") {
                    GeometryReader { geometry in
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(binding.state.uuid.uuidString)
                                .lineLimit(1)
                                .frame(
                                    minWidth: geometry.size.width,
                                    minHeight: geometry.size.height,
                                    maxHeight: geometry.size.height,
                                    alignment: .trailing
                                )
                        }
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            alignment: .trailing
                        )
                    }
                }
            }
            
            Section(header: Text("Characteristics")) {
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
                                NavigationLink(destination: CharacteristicView(of: characteristic, holding: deps)) {
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
                                model.discover()
                            }
                        }
                    }
                }
            }
        }
        .onAppear() {
           model.discover()
        }
        .navigationTitle("Service")
        .navigationBarItems(trailing: trailingNavigationBarItem)
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
                ServiceView(
                    observing: wrapper.value,
                    holding: .makeStub()
                )
            }
            .previewDisplayName(wrapper.description)
            .previewLayout(.sizeThatFits)
        }
    }
}
