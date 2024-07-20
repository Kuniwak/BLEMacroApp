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
    @State public var isDialogPresent: Bool = false
    
    
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
    
    
    public func presentAlert() -> some View {
        isDialogPresent.toggle()
        return self
    }
    
    
    public var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Value")) {
                    LabeledContent("Value") {
                        HStack {
                            Text(HexEncoding.upper.encode(data: characteristicBinding.state.value.data))
                            
                            Button(action: {
                                characteristicModel.read()
                            }) {
                                Image(systemName: SFSymbol5.Arrow.clockwise.rawValue)
                            }
                            .disabled(!characteristicBinding.state.value.properties.contains(.read))

                            Button(action: {
                                isDialogPresent = true
                            }) {
                                Image(systemName: SFSymbol5.pencil.rawValue)
                            }
                            .disabled(!characteristicBinding.state.value.properties.contains(.write))
                        }
                    }
                }
                
                Section(header: Text("Properties")) {
                    if characteristicBinding.state.value.properties.isEmpty {
                        Text("No Properties")
                    } else {
                        if characteristicBinding.state.value.properties.contains(.broadcast) {
                            LabeledContent("Broadcast") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.read) {
                            LabeledContent("Read") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.write) {
                            LabeledContent("Write") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.notify) {
                            LabeledContent("Notify") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.indicate) {
                            LabeledContent("Indicate") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.writeWithoutResponse) {
                            LabeledContent("Write Without Response") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.authenticatedSignedWrites) {
                            LabeledContent("Authenticated Signed Writes") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.extendedProperties) {
                            LabeledContent("Extended Properties") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.notifyEncryptionRequired) {
                            LabeledContent("Notify Encryption Required") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.indicateEncryptionRequired) {
                            LabeledContent("Indicate Encryption Required") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.notifyEncryptionRequired) {
                            LabeledContent("Notify Encryption Required") {
                                Text("Yes")
                            }
                        }
                        if characteristicBinding.state.value.properties.contains(.indicateEncryptionRequired) {
                            LabeledContent("Indicate Encryption Required") {
                                Text("Yes")
                            }
                        }
                    }
                }
                
                Section(header: Text("Descriptors")) {
                    switch characteristicBinding.state.connection {
                    case .notConnectable:
                        HStack {
                            Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                                .foregroundStyle(Color(.error))
                            Text("Not Connectable")
                                .foregroundStyle(Color(.error))
                        }
                    case .connected, .connecting, .connectionFailed, .disconnected, .disconnecting:
                        if let descriptors = characteristicBinding.state.discovery.values {
                            if descriptors.isEmpty {
                                Text("No Descriptors")
                                    .foregroundStyle(Color(.weak))
                            } else {
                                ForEach(descriptors) { descriptor in
                                    DescriptorRow(observing: descriptor)
                                }
                            }
                        } else if characteristicBinding.state.discovery.isDiscovering {
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
                                    characteristicModel.discover()
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear() {
            characteristicModel.discover()
        }
        .navigationTitle("Characteristic")
        .navigationBarItems(trailing: trailingNavigationBarItem)
        .alert("Write Value", isPresented: $isDialogPresent) {
            TextField("Enter Hex Data", text: .constant(""))
                .autocapitalization(.none)
                .keyboardType(.asciiCapable)
            
            Button("Request") {
                characteristicModel.write(type: .withResponse)
            }
            .disabled(!hexDataBinding.state.isSuccess)
            
            Button("Command") {
                characteristicModel.write(type: .withoutResponse)
            }
            .disabled(!hexDataBinding.state.isSuccess)
            
            Button("Cancel", role: .cancel) {}
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
    
    let values: [Data] = [
        Data(),
        Data([0x01, 0x02, 0x03]),
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
    
    let states2: [CharacteristicModelState] = values.map { value in
        .makeSuccessfulStub(value: .makeSuccessfulStub(data: value))
    }

    let states3: [CharacteristicModelState] = discovery.map { discovery in
        .makeSuccessfulStub(discovery: discovery)
    }
    
    let states4: [CharacteristicModelState] = connections.map { connection in
        .makeSuccessfulStub(connection: connection)
    }
    
    return (states1 + states2 + states3 + states4)
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
                .presentAlert()
            }
            .previewDisplayName(wrapper.description)
            .previewLayout(.sizeThatFits)
        }
    }
}
