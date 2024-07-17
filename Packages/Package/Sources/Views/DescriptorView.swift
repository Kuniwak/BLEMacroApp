import SwiftUI
import Models
import ViewFoundation
import Logger
import SFSymbol


public struct DescriptorView: View {
    @ObservedObject private var binding: ViewBinding<ConnectableDescriptorModelState, AnyConnectableDescriptorModel>
    private let model: any ConnectableDescriptorModelProtocol
    private let deps: DependencyBag
    private let modelLogger: ConnectableDescriptorModelLogger
    
    public init(observing model: any ConnectableDescriptorModelProtocol, holding deps: DependencyBag) {
        self.binding = ViewBinding(source: model.eraseToAny())
        self.model = model
        self.modelLogger = ConnectableDescriptorModelLogger(observing: model, loggingBy: deps.logger)
        self.deps = deps
    }
    
    
    public var body: some View {
        switch binding.state.connection {
        case .notConnectable:
            HStack {
                Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                    .foregroundStyle(Color(.error))
                Text("Not Connectable")
                    .foregroundStyle(Color(.error))
            }
        case .connected, .connecting, .connectionFailed, .disconnected, .disconnecting:
            switch binding.state.descriptor.value {
            case .success(let value):
                Grid {
                    GridRow {
                        Text("Value")
                        
                        if let value {
                            Text("\(value)")
                                .foregroundStyle(Color(.normal))
                        } else {
                            Text("(unknown)")
                                .foregroundStyle(Color(.weak))
                        }
                    }
                    
                    GridRow {
                        Text("")
                    }
                }
            case .failure(let error):
                Text("Error: \(error)")
                    .foregroundStyle(Color(.error))
            }
        }
    }
}
