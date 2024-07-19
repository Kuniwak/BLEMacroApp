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
            Section(header: Text("Descriptors")) {
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
                                DescriptorRow(observing: descriptor)
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
