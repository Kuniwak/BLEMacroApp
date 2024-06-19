import SwiftUI
import CoreBluetooth
import Models


public struct CharacteristicList: View {
    @ObservedObject private var projected: StateProjection<StateMachineArrayState<CBUUID, CharacteristicModelState, AnyCharacteristicModel>>
    
    
    public init(observing modelArray: CharacteristicsModel) {
        self.projected = StateProjection.project(stateMachine: modelArray)
    }
    
    
    public var body: some View {
        if projected.state.isEmpty {
            Text("No Services")
                .foregroundStyle(Color(.weak))
        } else {
            ForEach(projected.state.stateMachines) { element in
                let service = element.stateMachine
                CharacteristicRow(observing: service)
            }
        }
    }
}
