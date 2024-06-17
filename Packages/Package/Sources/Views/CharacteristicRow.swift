import SwiftUI
import Combine
import CoreBluetooth
import CoreBluetoothStub
import Logger
import Models
import ModelStubs
import PreviewHelper


public struct CharacteristicRow: View {
    @ObservedObject private var model: AnyCharacteristicModel
    
    
    public init(observing model: any CharacteristicModelProtocol) {
        self.model = model.eraseToAny()
    }
    
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let name = model.state.name {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Color(.normal))
            } else {
                Text("(no name)")
                    .font(.headline)
                    .foregroundStyle(Color(.weak))
            }
            
            Text(model.uuid.uuidString)
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
                .makeStub(
                    uuid: CBUUID(nsuuid: StubUUID.zero),
                    name: "Example"
                ),
                .makeStub(
                    uuid: CBUUID(nsuuid: StubUUID.zero),
                    name: nil
                ),
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
