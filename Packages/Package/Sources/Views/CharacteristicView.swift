import SwiftUI
import BLEInternal
import Models
import ModelStubs
import ViewFoundation
import SFSymbol
import PreviewHelper


public struct CharacteristicView: View {
    @ObservedObject private var characteristicBinding: ViewBinding<CharacteristicModelState, AnyCharacteristicModel>
    @ObservedObject private var hexDataBinding: ViewBinding<Result<Data, HexDataModelFailure>, AnyHexDataModel>
    @State private var isDialogPresent: Bool = false
    @State private var valueToWrite: String = "" {
        didSet {
            hexDataModel.update(byString: valueToWrite)
        }
    }
    
    private let deps: DependencyBag
    private let characteristicModel: any CharacteristicModelProtocol
    private let hexDataModel: any HexDataModelProtocol

    
    public init(of characteristicModel: any CharacteristicModelProtocol, holding deps: DependencyBag) {
        self.characteristicBinding = ViewBinding(source: characteristicModel.eraseToAny())
        let hexDataModel = HexDataModel(startsWith: .success(Data()))
        self.hexDataBinding = ViewBinding(source: hexDataModel.eraseToAny())
        self.deps = deps
        self.characteristicModel = characteristicModel
        self.hexDataModel = hexDataModel
    }
    
    
    public func presentAlert() {
        isDialogPresent = true
    }
    
    
    public var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Value")) {
                    Button("Write") {
                        isDialogPresent = true
                    }
                    .disabled(!characteristicBinding.state.value.properties.contains(.write))
                }
            }
            
            DescriptorsView(observing: characteristicModel, holding: deps)
        }
        .onAppear() {
            characteristicModel.discover()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Characteristic")
                        .font(.headline)
                    Text(characteristicBinding.state.name ?? characteristicBinding.state.uuid.uuidString)
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                trailingNavigationBarItem
            }
        }
        .alert("Write Value", isPresented: $isDialogPresent) {
            TextField("Enter Hex Data", text: $valueToWrite)
            
            Button("Write") {
                characteristicModel.write(type: .withResponse)
            }
            .disabled(!hexDataBinding.state.isSuccess)
            
            Button("Write") {
                characteristicModel.write(type: .withoutResponse)
            }
            .disabled(!hexDataBinding.state.isSuccess)
            
            Button("Cancel", role: .cancel) {
            }
        }
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            if characteristicBinding.state.connection.canConnect {
                Button("Connect") {
                    characteristicModel.connect()
                }
            } else if characteristicBinding.state.connection.isConnected {
                Button("Disconnect") {
                    characteristicModel.disconnect()
                }
            } else {
                ProgressView()
            }
        }
    }
}


extension Result {
    fileprivate var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
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


internal struct CharacteristicView_Previews: PreviewProvider {
    internal static var previews: some View {
        ForEach(stubsForPreview()) { wrapper in
            NavigationStack {
                CharacteristicView(
                    of: wrapper.value,
                    holding: .makeStub()
                )
            }
            .previewDisplayName(wrapper.description)
            .previewLayout(.sizeThatFits)
        }
    }
}
