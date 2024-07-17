import SwiftUI
import Logger
import Models
import ModelStubs
import ViewFoundation
import SFSymbol
import PreviewHelper


public struct DescriptorsView: View {
    @ObservedObject private var binding: ViewBinding<CharacteristicModelState, AnyCharacteristicModel>
    private let model: any CharacteristicModelProtocol
    private let deps: DependencyBag
    private let modelLogger: CharacteristicModelLogger
    
    
    public init(
        observing model: any CharacteristicModelProtocol,
        holding deps: DependencyBag
    ) {
        self.binding = ViewBinding(source: model.eraseToAny())
        self.model = model
        self.modelLogger = CharacteristicModelLogger(observing: model, loggingBy: deps.logger)
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
                if let descriptors = binding.state.discovery.values {
                    if descriptors.isEmpty {
                        Text("No Descriptors")
                            .foregroundStyle(Color(.weak))
                    } else {
                        ForEach(descriptors) { descriptor in
                            let connectableDescriptor = ConnectableDescriptorModel(
                                operateingBy: descriptor,
                                connectingBy: deps.connectionModel
                            )
                            
                            NavigationLink(destination: descriptorView(for: connectableDescriptor)) {
                                DescriptorRow(observing: descriptor)
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Descriptors")
                        .font(.headline)
                    Text(model.state.name ?? model.state.uuid.uuidString)
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                trailingNavigationBarItem
            }
        }
    }
    
    
    private func descriptorView(for descriptor: any ConnectableDescriptorModelProtocol) -> some View {
        DescriptorView(observing: descriptor, holding: deps)
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


private func stubsForPreview() -> [Previewable<AnyCharacteristicModel>] {
    let names: [String?] = [
        nil,
        "Example",
    ]
    
    let discovery: [DescriptorDiscoveryModelState] = [
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
    
    let states1: [CharacteristicModelState] = names.map { name in
        .makeSuccessfulStub(name: name)
    }

    let states2: [CharacteristicModelState] = discovery.map { discovery in
        .makeSuccessfulStub(discovery: discovery)
    }
    
    let state3: [CharacteristicModelState] = connections.map { connection in
        .makeSuccessfulStub(connection: connection)
    }
    
    return (states1 + states2 + state3)
        .map { state in
            return Previewable(
                StubCharacteristicModel(state: state).eraseToAny(),
                describing: "\(state.debugDescription)"
            )
        }
}


internal struct DescriptorsView_Previews: PreviewProvider {
    internal static var previews: some View {
        ForEach(stubsForPreview()) { wrapper in
            NavigationStack {
                DescriptorsView(
                    observing: wrapper.value,
                    holding: DependencyBag(
                        connectionModel: StubConnectionModel(),
                        logger: NullLogger()
                    )
                )
            }
            .previewDisplayName(wrapper.description)
            .previewLayout(.sizeThatFits)
        }
    }
}
