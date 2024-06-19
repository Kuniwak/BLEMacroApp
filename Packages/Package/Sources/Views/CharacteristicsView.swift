import SwiftUI
import Combine
import Logger
import Models
import ModelStubs
import SFSymbol


public struct CharacteristicsView: View {
    @ObservedObject private var projected: StateProjection<ServiceModelState>
    private let model: any ServiceModelProtocol
    private let modelLogger: ServiceModelLogger
    private let logger: any LoggerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(
        observing model: any ServiceModelProtocol,
        loggingBy logger: any LoggerProtocol
    ) {
        self.projected = StateProjection.project(stateMachine: model)
        self.model = model
        self.modelLogger = ServiceModelLogger(observing: model, loggingBy: logger)
        self.logger = logger
    }
    
    
    public var body: some View {
        List {
            switch projected.state.discovery {
            case .notDiscoveredYet, .discoveryFailed(_, nil):
                HStack {
                    Text("Discovery Not Started.")
                        .foregroundStyle(Color(.weak))
                    Button("Start") {
                        Task { await model.discover() }
                    }
                }
            case .discovering(nil):
                VStack {
                    Text("Discovering...")
                        .foregroundStyle(Color(.weak))
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            case .discovered(let characteristics), .discovering(.some(let characteristics)), .discoveryFailed(_, .some(let characteristics)):
                CharacteristicList(observing: characteristics)
            }
        }
        .navigationTitle(projected.state.name ?? projected.state.uuid.uuidString)
        .navigationBarItems(trailing: trailingNavigationBarItem)
    }
    
    
    private func descriptorView(model: any CharacteristicModelProtocol) -> some View {
        // TODO
        Text(projected.state.uuid.uuidString)
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            if projected.state.connection.canConnect {
                Button("Connect") {
                    Task { await model.connect() }
                }
            } else if projected.state.connection.isConnected {
                Button("Disconnect") {
                    Task { await model.disconnect() }
                }
            } else {
                ProgressView()
            }
        }
    }
}
