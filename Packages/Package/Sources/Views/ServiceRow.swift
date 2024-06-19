import SwiftUI
import Models
import ModelStubs
import PreviewHelper


public struct ServiceRow: View {
    @ObservedObject private var model: StateProjection<ServiceModelState>
    
    
    public init(observing model: any ServiceModelProtocol) {
        self.model = StateProjection(projecting: model)
    }
    
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let name = model.state.name {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Color(.normal))
            } else {
                Text("(no name)")
                    .font(.headline)
                    .foregroundStyle(Color(.weak))
            }
            
            Text(model.state.uuid.uuidString)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .foregroundStyle(Color(.weak))
        }
    }
}


#Preview("with NavigationLink") {
    let models = [nil, "Example Service"]
        .map { name -> AnyServiceModel in
            StubServiceModel(
                state: .makeStub(
                    name: name,
                    discovery: .notDiscoveredYet
                )
            ).eraseToAny()
        }
    
    NavigationStack {
        List {
            ForEach(models) { model in
                NavigationLink(destination: Text("TODO")) {
                    ServiceRow(observing: model)
                }
            }
        }
    }
}


#Preview("without NavigationLink") {
    let models = [nil, "Example Service"]
        .map { name -> AnyServiceModel in
            StubServiceModel(
                state: .makeStub(
                    discoveryState: .notDiscoveredYet,
                    name: name
                )
            ).eraseToAny()
        }

    List {
        ForEach(models) { model in
            ServiceRow(observing: model)
        }
    }
}
