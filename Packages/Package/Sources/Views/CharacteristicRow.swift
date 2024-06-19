import SwiftUI
import Combine
import CoreBluetooth
import CoreBluetoothStub
import Logger
import Models
import ModelStubs
import PreviewHelper


public struct CharacteristicRow: View {
    @ObservedObject private var projected: StateProjection<CharacteristicModelState>
    
    
    public init(observing model: any CharacteristicModelProtocol) {
        self.projected = StateProjection.project(stateMachine: model)
    }
    
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let name = projected.state.name {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Color(.normal))
            } else {
                Text("(no name)")
                    .font(.headline)
                    .foregroundStyle(Color(.weak))
            }
            
            Text(projected.state.uuid.uuidString)
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
                Previewable(state, describing: state.description)
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
