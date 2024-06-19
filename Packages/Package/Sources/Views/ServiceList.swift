import SwiftUI
import CoreBluetooth
import Models


public struct ServiceList: View {
    @ObservedObject private var projected: StateProjection<StateMachineArrayState<CBUUID, ServiceModelState, AnyServiceModel>>
    
    
    public init(observing modelArray: ServicesModel) {
        self.projected = StateProjection.project(stateMachine: modelArray)
    }
    
    
    public var body: some View {
        if projected.state.isEmpty {
            Text("No Services")
                .foregroundStyle(Color(.weak))
        } else {
            ForEach(projected.state.stateMachines) { element in
                let service = element.stateMachine
                ServiceRow(observing: service)
            }
        }
    }
}
