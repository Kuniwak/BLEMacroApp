import SwiftUI
import CoreBluetooth
import BLEInternal
import Models
import ModelStubs
import ViewFoundation
import SFSymbol
import PreviewHelper


public struct CharacteristicView: View {
    @StateObject private var characteristicBinding: ViewBinding<CharacteristicModelState, AnyCharacteristicModel>
    @State public var isDialogPresent: Bool = false
    @State public var hexString: String = ""
    @State public var hadWrote: Bool = false
    private let characteristicLogger: CharacteristicModelLogger
    private let deps: DependencyBag

    
    public init(of characteristicModel: any CharacteristicModelProtocol, holding deps: DependencyBag) {
        self._characteristicBinding = StateObject(wrappedValue: ViewBinding(source: characteristicModel.eraseToAny()))
        self.characteristicLogger = CharacteristicModelLogger(
            observing: characteristicModel,
            loggingBy: deps.logger
        )
        self.deps = deps
    }
    
    
    public var body: some View {
        Form {
            Section(header: Text("Characteristic")) {
                LabeledContent("Name") {
                    if let name = characteristicBinding.state.name {
                        ScrollableText(name)
                    } else {
                        Text("(no name)")
                    }
                }
                
                LabeledContent("UUID") {
                    ScrollableText(characteristicBinding.state.uuid.uuidString)
                }
            }
            
            Section(header: Text("Value")) {
                if characteristicBinding.state.value.properties.contains(.read) {
                    LabeledContent("Hexadecimal") {
                        if characteristicBinding.state.value.data.isEmpty {
                            Text("No Data")
                        } else {
                            ScrollableText("0x\(HexEncoding.upper.encode(data: characteristicBinding.state.value.data))")
                        }
                    }
                    
                    if !characteristicBinding.state.value.data.isEmpty,
                       let string = String(data: characteristicBinding.state.value.data, encoding: .utf8),
                       doesNotContainControlCharactersExceptWhitespacesAndNewLines(string: string) {
                        LabeledContent("UTF-8 Text") {
                            ScrollableText(string)
                        }
                    }
                    
                    Button("Refresh") {
                        characteristicBinding.source.read()
                    }
                    .disabled(!characteristicBinding.state.connection.isConnected)
                    
                    if !characteristicBinding.state.connection.isConnected {
                        Button("Connect to Refresh") {
                            characteristicBinding.source.connect()
                        }
                    }
                } else {
                    Text("Not Readable")
                        .foregroundStyle(Color(.weak))
                }
            }
            
            Section(header: Text("Actions")) {
                if !characteristicBinding.state.value.properties.contains(.write) &&
                    !characteristicBinding.state.value.properties.contains(.writeWithoutResponse) &&
                    !characteristicBinding.state.value.properties.contains(.notify) {
                    Text("No Available Actions")
                        .foregroundStyle(Color(.weak))
                }
                
                if characteristicBinding.state.value.properties.contains(.write) || characteristicBinding.state.value.properties.contains(.writeWithoutResponse) {
                    Button("Write") {
                        isDialogPresent = true
                    }
                    .disabled(!characteristicBinding.state.connection.isConnected)
                    
                    if hadWrote {
                        if let error = characteristicBinding.state.value.error {
                            LabeledContent("Result") {
                                Text("Failed")
                            }
                            
                            LabeledContent("Error") {
                                ScrollableText(error.description, foregroundColor: Color(.error))
                            }
                        } else {
                            LabeledContent("Result") {
                                Text("Success")
                            }
                        }
                    }
                }
                
                if characteristicBinding.state.value.properties.contains(.notify) {
                    if characteristicBinding.state.value.isNotifying {
                        Button("Unsubscribe") {
                            characteristicBinding.source.setNotify(false)
                        }
                        .disabled(!characteristicBinding.state.connection.isConnected)
                    } else {
                        Button("Subscribe") {
                            characteristicBinding.source.setNotify(true)
                        }
                        .disabled(!characteristicBinding.state.connection.isConnected)
                    }
                }
                
                if !characteristicBinding.state.value.properties.contains(.write) &&
                    !characteristicBinding.state.value.properties.contains(.writeWithoutResponse) &&
                    !characteristicBinding.state.value.properties.contains(.notify) &&
                    !characteristicBinding.state.connection.isConnected {
                    Button("Connect to Write or Notify") {
                        characteristicBinding.source.connect()
                    }
                }
            }
            
            Section(header: Text("Properties")) {
                if characteristicBinding.state.value.properties.isEmpty {
                    Text("No Properties")
                        .foregroundStyle(Color(.weak))
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
                    if characteristicBinding.state.value.properties.contains(.writeWithoutResponse) {
                        LabeledContent("Write Without Response") {
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
                        Text("Not Connectable")
                    }
                    .foregroundStyle(Color(.weak))
                case .connected, .connecting, .connectionFailed, .disconnected, .disconnecting:
                    if let descriptors = characteristicBinding.state.discovery.values {
                        if descriptors.isEmpty {
                            Text("No Descriptors")
                                .foregroundStyle(Color(.weak))
                        } else {
                            ForEach(descriptors) { descriptor in
                                NavigationLink(destination: DescriptorView(observing: descriptor)) {
                                    DescriptorRow(observing: descriptor)
                                }
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
                                characteristicBinding.source.discover()
                            }
                        }
                    }
                }
            }
        }
        .onAppear() {
            characteristicBinding.source.discover()
            characteristicBinding.source.read()
        }
        .navigationTitle("Characteristic")
        .navigationBarItems(trailing: trailingNavigationBarItem)
        .alert("Write Value", isPresented: $isDialogPresent) {
            TextField("Enter Hex Data", text: $hexString)
                .autocapitalization(.none)
                .keyboardType(.asciiCapable)
                .onChange(of: hexString) { _, newValue in
                    hexString = newValue.filter { $0.isHexDigit }.uppercased()
                    characteristicBinding.source.updateHexString(with: hexString)
                }
            
            if characteristicBinding.state.value.properties.contains(.write) {
                Button("Request") {
                    characteristicBinding.source.write(type: .withResponse)
                    hadWrote = true
                }
                .disabled(hexString.isEmpty)
            }
            
            if characteristicBinding.state.value.properties.contains(.writeWithoutResponse) {
                Button("Command") {
                    characteristicBinding.source.write(type: .withoutResponse)
                    hadWrote = true
                }
                .disabled(hexString.isEmpty)
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            switch characteristicBinding.state.connection {
            case .connecting, .disconnecting:
                ProgressView()
            case .connected:
                Button("Disconnect") {
                    characteristicBinding.source.disconnect()
                }
            case .notConnectable, .disconnected, .connectionFailed:
                Button("Connect") {
                    characteristicBinding.source.connect()
                }
                .disabled(!characteristicBinding.state.connection.canConnect)
            }
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
        Data([0x01, 0x02]),
        Data("Hello, World!".utf8),
    ]
    
    let properties: [CBCharacteristicProperties] = [
        [],
        [.read],
        [.write],
        [.writeWithoutResponse],
        [.read, .notify],
        [.read, .write, .writeWithoutResponse, .notify],
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
    
    let states3: [CharacteristicModelState] = properties.map { properties in
        .makeSuccessfulStub(value: .makeSuccessfulStub(properties: properties))
    }

    let states4: [CharacteristicModelState] = discovery.map { discovery in
        .makeSuccessfulStub(discovery: discovery)
    }
    
    let states5: [CharacteristicModelState] = connections.map { connection in
        .makeSuccessfulStub(connection: connection)
    }
    
    return (states1 + states2 + states3 + states4 + states5)
        .map { state in
            return Previewable(
                StubCharacteristicModel(state: state).eraseToAny(),
                describing: "\(state.debugDescription)"
            )
        }
}


fileprivate let controlCharactersExceptWhitespacesAndNewLines = CharacterSet.controlCharacters.subtracting(.whitespacesAndNewlines)


fileprivate func doesNotContainControlCharactersExceptWhitespacesAndNewLines(string: String) -> Bool {
    return string.unicodeScalars.allSatisfy { !controlCharactersExceptWhitespacesAndNewLines.contains($0)
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
