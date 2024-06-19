import SwiftUI
import Combine
import Logger
import Models
import ModelStubs
import SFSymbol


public struct CharacteristicsView: View {
    @ObservedObject private var model: StateProjection<ServiceModelState>
    private let modelLogger: ServiceModelLogger
    private let logger: any LoggerProtocol
    
    
    public init(
        observing model: any ServiceModelProtocol,
        loggingBy logger: any LoggerProtocol
    ) {
        self.model = StateProjection(projecting: model)
        self.modelLogger = ServiceModelLogger(observing: model, loggingBy: logger)
    }
    
    
    public var body: some View {
        List {
            switch model.state.discovery {
            case .notDiscoveredYet:
                Text("Not discovered yet")
                    .foregroundStyle(Color(.weak))
            case .discovered(let characteristics):
                ForEach(characteristics) { characteristic in
                    NavigationLink(destination: Text("TODO")) {
                        CharacteristicRow(observing: characteristic)
                    }
                }
            case .discoverFailed(let error):
                HStack {
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                        .foregroundStyle(Color(.error))
                    Text("E: \(error)")
                        .foregroundStyle(Color(.error))
                }
            case .discovering:
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .navigationTitle(name)
        .navigationBarItems(trailing: trailingNavigationBarItem)
    }
    
    
    private var name: String {
        switch model.state.name {
        case .success(.some(let name)):
            return name
        case .success(.none):
            return "(no name)"
        case .failure(let error):
            return "E: \(error)"
        }
    }
    
    
    private func descriptorView(model: any CharacteristicModelProtocol) -> some View {
        // TODO
        Text(model.uuid.uuidString)
    }
    
    
    private var trailingNavigationBarItem: some View {
        Group {
            if model.state.discoveryState.canConnect {
                Button("Connect", action: model.connect)
            } else if model.state.discoveryState.isConnected {
                Button("Disconnect", action: model.disconnect)
            } else {
                ProgressView()
            }
        }
    }
}
