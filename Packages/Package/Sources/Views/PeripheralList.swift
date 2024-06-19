import SwiftUI
import Models


public struct PeripheralList: View {
    @ObservedObject private var projection: StateProjection<[StateMachineArrayElement<UUID, PeripheralModelState, AnyPeripheralModel>]>
    private let model: PeripheralsModel

    
    public init(observing model: PeripheralsModel) {
        self.projection = StateProjection.project(stateMachine: model)
        self.model = model
    }
    
    
    public var body: some View {
        ForEach(projection.state) { element in
            let state = element.state
            let peripheral = element.stateMachine
            if state.connection.canConnect {
                NavigationLink(destination: servicesView(peripheral)) {
                    PeripheralRow(observing: peripheral)
                }
            } else {
                PeripheralRow(observing: peripheral)
            }
        }
    }
    
    
    private func servicesView(_ peripheral: any PeripheralModelProtocol) -> some View {
        let model = self.model
        return ServicesView(observing: peripheral, loggingBy: logger)
            .onAppear() {
                model.stopScan()
                peripheral.discover()
            }
            .onDisappear() {
                peripheral.disconnect()
            }
    }
}

