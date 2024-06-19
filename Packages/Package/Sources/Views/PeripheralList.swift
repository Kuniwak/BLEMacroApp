import Foundation
import SwiftUI
import Logger
import Models


public struct PeripheralList: View {
    @ObservedObject private var projection: StateProjection<StateMachineArrayState<UUID, PeripheralModelState, AnyPeripheralModel>>
    private let modelArray: PeripheralsModel
    private let model: any PeripheralSearchModelProtocol
    private let logger: any LoggerProtocol

    
    public init(
        projecting modelArray: PeripheralsModel,
        stoppingScanningBy model: any PeripheralSearchModelProtocol,
        loggingBy logger: any LoggerProtocol
    ) {
        self.projection = StateProjection.project(stateMachine: modelArray)
        self.modelArray = modelArray
        self.model = model
        self.logger = logger
    }
    
    
    public var body: some View {
        if projection.state.isEmpty {
            HStack {
                Spacer()
                Text("No devices found")
                Spacer()
            }
            .foregroundStyle(Color(.weak))
        } else {
            ForEach(projection.state.stateMachines) { element in
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
    }
    
    
    private func servicesView(_ peripheral: any PeripheralModelProtocol) -> some View {
        let model = self.model
        return ServicesView(observing: peripheral, loggingBy: logger)
            .onAppear() {
                Task { await model.stopScan() }
                Task { await peripheral.discover() }
            }
            .onDisappear() {
                Task { await peripheral.disconnect() }
            }
    }
}

