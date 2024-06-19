import SwiftUI
import Models
import ModelStubs
import PreviewHelper


public struct ServiceRow: View {
    @ObservedObject private var projected: StateProjection<ServiceModelState>
    
    
    public init(observing model: any ServiceModelProtocol) {
        self.projected = StateProjection.project(stateMachine: model)
    }
    
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let name = projected.state.name {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Color(.normal))
            } else {
                Text("(no name)")
                    .font(.headline)
                    .foregroundStyle(Color(.weak))
            }
            
            Text(projected.state.uuid.uuidString)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .foregroundStyle(Color(.weak))
        }
    }
}


private func stubsForPreview() -> [Previewable<AnyServiceModel>] {
    let names: [String?] = [nil, "Example Service"]
    return names
        .map { name -> Previewable<AnyServiceModel> in
            let state: ServiceModelState = .makeStub(
                name: name,
                discovery: .notDiscoveredYet
            )
            let model = StubServiceModel(state: state).eraseToAny()
            return Previewable(model, describing: state.description)
        }

}


#Preview("with NavigationLink") {
    NavigationStack {
        List {
            ForEach(stubsForPreview()) { wrapper in
                NavigationLink(destination: Text("TODO")) {
                    ServiceRow(observing: wrapper.value)
                }
            }
        }
    }
}


#Preview("without NavigationLink") {
    List {
        ForEach(stubsForPreview()) { wrapper in
            ServiceRow(observing: wrapper.value)
        }
    }
}
