import SwiftUI
import Combine
import Logger
import Models
import ModelStubs
import ViewFoundation
import SFSymbol


public struct CharacteristicsView: View {
    @ObservedObject private var binding: ViewBinding<ServiceModelState, AnyServiceModel>
    private let model: any ServiceModelProtocol
    private let modelLogger: ServiceModelLogger
    private let logger: any LoggerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(
        observing model: any ServiceModelProtocol,
        loggingBy logger: any LoggerProtocol
    ) {
        self.binding = ViewBinding(source: model.eraseToAny())
        self.model = model
        self.modelLogger = ServiceModelLogger(observing: model, loggingBy: logger)
        self.logger = logger
    }
    
    
    public var body: some View {
        List {
            switch binding.state.discovery {
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
                if characteristics.isEmpty {
                    Text("No Characteristics")
                        .foregroundStyle(Color(.weak))
                } else {
                    ForEach(characteristics) { characteristic in
                        CharacteristicRow(observing: characteristic)
                    }
                }
            }
        }
        .navigationTitle(binding.state.name ?? binding.state.uuid.uuidString)
        .navigationBarItems(trailing: trailingNavigationBarItem)
    }
    
    
    private func descriptorView(model: any CharacteristicModelProtocol) -> some View {
        // TODO
        Text(binding.state.uuid.uuidString)
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            if binding.state.connection.canConnect {
                Button("Connect") {
                    Task { await model.connect() }
                }
            } else if binding.state.connection.isConnected {
                Button("Disconnect") {
                    Task { await model.disconnect() }
                }
            } else {
                ProgressView()
            }
        }
    }
}
