import SwiftUI
import Models
import ModelStubs
import BLEInternal
import ViewFoundation
import PreviewHelper
import SFSymbol


public struct DescriptorView: View {
    @StateObject private var binding: ViewBinding<DescriptorModelState, AnyDescriptorModel>
    @State private var isDialogPresent: Bool = false
    @State private var hexString: String = ""
    @State private var hadWrote: Bool = false
    
    
    public init(observing model: any DescriptorModelProtocol) {
        self._binding = StateObject(wrappedValue: ViewBinding(source: model.eraseToAny()))
    }
    
    
    public var body: some View {
        Form {
            Section(header: Text("Characteristic")) {
                LabeledContent("Name") {
                    if let name = binding.state.name {
                        ScrollableText(name)
                    } else {
                        Text("(no name)")
                    }
                }
                
                LabeledContent("UUID") {
                    ScrollableText(binding.state.uuid.uuidString)
                }
            }
            
            Section(header: Text("Value")) {
                if let value = binding.state.value.value {
                    switch value {
                    case .data(let data):
                        LabeledContent("Hexadecimal") {
                            ScrollableText("0x" + HexEncoding.upper.encode(data: data))
                        }
                    case .string(let string):
                        LabeledContent("String") {
                            ScrollableText(string)
                        }
                    case .number(let number):
                        LabeledContent("Number") {
                            ScrollableText(number.description)
                        }
                    case .uint64(let uint64):
                        LabeledContent("Number") {
                            Text(uint64.description)
                        }
                    case .unknown(let anyValue):
                        LabeledContent("Unknown Type") {
                            ScrollableText("\(anyValue)")
                        }
                    }
                } else {
                    LabeledContent("Value") {
                        Text("No Data")
                    }
                }
                
                Button("Refresh") {
                    binding.source.read()
                }
                .disabled(!binding.state.connection.isConnected)
            }
            
            Section(header: Text("Actions")) {
                Button("Write") {
                    isDialogPresent = true
                }
                .disabled(!binding.state.connection.isConnected || !binding.state.value.canWrite)
                
                if !binding.state.value.canWrite {
                    HStack(alignment: .top) {
                        Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                        Text("CoreBluetooth does not support writing to CCCD. Use \"Subscribe\" instead.")
                            .font(.caption)
                    }
                    .padding([.top, .bottom], 4)
                    .foregroundColor(Color(.weak))
                }
                
                if hadWrote {
                    if let error = binding.state.value.error {
                        LabeledContent("Result") {
                            Text("Failed")
                        }
                        
                        LabeledContent("Error") {
                            ScrollableText(error.description)
                        }
                    } else {
                        LabeledContent("Result") {
                            Text("Success")
                        }
                    }
                }
                
                if !binding.state.connection.isConnected {
                    Button("Connect to Write") {
                        binding.source.connect()
                    }
                }
            }
        }
        .onAppear() {
            binding.source.read()
        }
        .navigationTitle("Descriptor")
        .navigationBarItems(trailing: trailingNavigationBarItem)
        .alert("Write Value", isPresented: $isDialogPresent) {
            TextField("Enter Hex Data", text: $hexString)
                .autocapitalization(.none)
                .keyboardType(.asciiCapable)
                .onChange(of: hexString) { _, newValue in
                    hexString = newValue.filter { $0.isHexDigit }.uppercased()
                    binding.source.updateHexString(with: hexString)
                }
            
            Button("Write") {
                binding.source.write()
            }
            .disabled(hexString.isEmpty)
            
            Button("Cancel", role: .cancel) {}
        }
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            switch binding.state.connection {
            case .connecting, .disconnecting:
                ProgressView()
            case .connected:
                Button("Disconnect") {
                    binding.source.disconnect()
                }
            case .notConnectable, .disconnected, .connectionFailed:
                Button("Connect") {
                    binding.source.connect()
                }
                .disabled(!binding.state.connection.canConnect)
            }
        }
    }
}


private func stubsForPreview() -> [Previewable<AnyDescriptorModel>] {
    let names: [String?] = [
        nil,
        "Example",
    ]
    
    let values: [DescriptorValue] = [
        .data(Data([0x01, 0x02, 0x03])),
        .string(String("Hello, World")),
        .number(NSNumber(value: 42)),
        .uint64(42),
        .unknown("Unknown")
    ]
    
    let connections: [ConnectionModelState] = [
        .notConnectable,
        .connected,
        .connecting,
        .connectionFailed(.init(description: "TEST")),
        .disconnected,
        .disconnecting,
    ]
    
    let states1: [DescriptorModelState] = names.map { name in
        .makeSuccessfulStub(
            name: name,
            value: .makeSuccessfulStub(),
            connection: .connected
        )
    }
    
    let states2: [DescriptorModelState] = values.map { value in
        .makeSuccessfulStub(
            value: .makeSuccessfulStub(value: value),
            connection: .connected
        )
    }
    
    let states3: [DescriptorModelState] = [
        .makeSuccessfulStub(
            value: .makeSuccessfulStub(canWrite: false),
            connection: .connected
        ),
    ]

    let states4: [DescriptorModelState] = connections.map { connection in
        .makeSuccessfulStub(connection: connection)
    }
    
    return (states1 + states2 + states3 + states4)
        .map { state in
            return Previewable(
                StubDescriptorModel(state: state).eraseToAny(),
                describing: "\(state.debugDescription)"
            )
        }
}


internal struct DescriptorView_Previews: PreviewProvider {
    internal static var previews: some View {
        ForEach(stubsForPreview()) { wrapper in
            NavigationStack {
                DescriptorView(
                    observing: wrapper.value
                )
            }
            .previewDisplayName(wrapper.description)
            .previewLayout(.sizeThatFits)
        }
    }
}
