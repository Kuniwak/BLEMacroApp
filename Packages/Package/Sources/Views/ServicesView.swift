import SwiftUI
import CoreBluetoothStub
import Logger
import Models
import ModelStubs
import PreviewHelper
import SFSymbol


public struct ServicesView: View {
    @ObservedObject private var model: StateProjection<PeripheralModelState>
    private let logger: any LoggerProtocol
    private let modelLogger: PeripheralModelLogger
    
    
    public init(observing model: any PeripheralModelProtocol, loggingBy logger: any LoggerProtocol) {
        self.model = StateProjection(projecting: model)
        self.logger = logger
        self.modelLogger = PeripheralModelLogger(observing: model, loggingBy: logger)
    }
    
    
    public var body: some View {
        List {
            switch model.state.connectionState {
            case .notConnectable:
                HStack {
                    Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                        .foregroundStyle(Color(.error))
                    Text("Not connectable")
                        .foregroundStyle(Color(.error))
                }
            default:
                if model.state.
                ForEach(services) { service in
                    ServiceRow(observing: service)
                }
            }
            case .disconnected(.some(let services)), .connecting(shouldDiscover: _, .some(let services)), .connected(.some(let services)), .disconnecting(.some(let services)), .connectionFailed(_, .some(let services)):
            case .disconnected(.none), .connecting(shouldDiscover: _, .none), .connected(.none), .disconnecting(.none), .connectionFailed(_, .none):
                Text("No services")
                    .foregroundStyle(Color(.weak))
            case .discovered(let services):
                ForEach(services) { service in
                    NavigationLink(destination: characteristicsView(model: service)) {
                        ServiceRow(observing: service)
                    }
                }
            case .discoveryFailed(let error):
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
    
    
    private func characteristicsView(model: any ServiceModelProtocol) -> some View {
        // TODO
        Text(model.state.uuid.uuidString)
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


internal struct ServicesView_Previews: PreviewProvider {
    internal static var previews: some View {
        let discoveryState: [ServiceDiscoveryState] = [
            .notConnectable,
            .disconnected(.none),
            .disconnected(.some([
                StubServiceModel(state: .makeStub(name: "Example Service")).eraseToAny(),
                StubServiceModel(state: .makeStub(name: nil)).eraseToAny(),
            ])),
            .connecting(shouldDiscover: false, .none),
            .connecting(shouldDiscover: false, .some([
                StubServiceModel(state: .makeStub(name: "Example Service")).eraseToAny(),
                StubServiceModel(state: .makeStub(name: nil)).eraseToAny(),
            ])),
            .connecting(shouldDiscover: true, .none),
            .connecting(shouldDiscover: true, .some([
                StubServiceModel(state: .makeStub(name: "Example Service")).eraseToAny(),
                StubServiceModel(state: .makeStub(name: nil)).eraseToAny(),
            ])),
            .connected(.none),
            .connected(.some([
                StubServiceModel(state: .makeStub(name: "Example Service")).eraseToAny(),
                StubServiceModel(state: .makeStub(name: nil)).eraseToAny(),
            ])),
            .disconnecting(.none),
            .disconnecting(.some([
                StubServiceModel(state: .makeStub(name: "Example Service")).eraseToAny(),
                StubServiceModel(state: .makeStub(name: nil)).eraseToAny(),
            ])),
            .connectionFailed(.init(description: "TEST"), .none),
            .connectionFailed(.init(description: "TEST"), .some([
                StubServiceModel(state: .makeStub(name: "Example Service")).eraseToAny(),
                StubServiceModel(state: .makeStub(name: nil)).eraseToAny(),
            ])),
            .discoveryFailed(.init(description: "TEST")),
            .discovering,
            .discovered([
                StubServiceModel(state: .makeStub(name: "Example Service")).eraseToAny(),
                StubServiceModel(state: .makeStub(name: nil)).eraseToAny(),
            ]),
        ]
        
        let names: [Result<String?, PeripheralModelFailure>] = [
            .success("Example"),
            .success(nil),
            .failure(.init(description: "TEST")),
        ]
        
        
        let states1: [PeripheralModelState] = discoveryState.map { discoveryState in
            PeripheralModelState(
                uuid: StubUUID.zero,
                discoveryState: discoveryState,
                rssi: .success(-50),
                name: .success("Example Device"),
                isConnectable: true,
                manufacturerData: nil
            )
        }
        
        let states2: [PeripheralModelState] = names.map { name in
            PeripheralModelState(
                uuid: StubUUID.zero,
                discoveryState: .disconnected(.none),
                rssi: .success(-50),
                name: name,
                isConnectable: true,
                manufacturerData: nil
            )
        }
        
        let wrappers = (states1 + states2).enumerated()
            .map { pair in
                var state = pair.1
                state.uuid = StubUUID.from(byte: UInt8(pair.0))
                let name: String
                switch state.name {
                case .success(.some(let value)):
                    name = value
                case .success(.none):
                    name = "nil"
                case .failure(let error):
                    name = "\(error)"
                }
                return Previewable(state, describing: "\(state.discoveryState.debugDescription) \(name)")
            }
        
        Group {
            ForEach(wrappers) { wrapper in
                NavigationStack {
                    ServicesView(
                        observing: StubPeripheralModel(state: wrapper.value),
                        loggingBy: NullLogger()
                    )
                }
                .previewDisplayName(wrapper.description)
            }
        }
    }
}
