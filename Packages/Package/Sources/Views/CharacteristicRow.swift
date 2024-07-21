import SwiftUI
import Combine
import CoreBluetooth
import CoreBluetoothStub
import Logger
import Models
import ModelStubs
import ViewFoundation
import PreviewHelper


public struct CharacteristicRow: View {
    @ObservedObject private var binding: ViewBinding<CharacteristicModelState, AnyCharacteristicModel>
    
    
    public init(observing model: any CharacteristicModelProtocol) {
        self.binding = ViewBinding(source: model.eraseToAny())
    }
    
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let name = binding.state.name {
                Text(name)
            } else {
                Text("(no name)")
                    .foregroundStyle(Color(.weak))
            }
            
            Text(binding.state.uuid.uuidString)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .foregroundStyle(Color(.weak))
        }
    }
}


#Preview {
    NavigationStack {
        List {
            let states: [CharacteristicModelState] = [
                .makeStub(name: "Example"),
                .makeStub(name: nil),
            ]
            
            let wrappers: [Previewable] = states.map { state in
                Previewable(state, describing: state.debugDescription)
            }
            
            ForEach(wrappers) { wrapper in
                CharacteristicRow(observing: StubCharacteristicModel(state: wrapper.value))
                NavigationLink(destination: Text("TODO")) {
                    CharacteristicRow(observing: StubCharacteristicModel(state: wrapper.value))
                }
            }
        }
    }
}
