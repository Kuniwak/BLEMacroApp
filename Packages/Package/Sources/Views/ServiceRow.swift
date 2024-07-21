import SwiftUI
import Models
import ModelStubs
import ViewFoundation
import PreviewHelper


public struct ServiceRow: View {
    @ObservedObject private var binding: ViewBinding<ServiceModelState, AnyServiceModel>
    
    
    public init(observing model: any ServiceModelProtocol) {
        self.binding = ViewBinding(source: model.eraseToAny())
    }
    
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let name = binding.state.name {
                Text(name)
            } else {
                Text("(no name)")
                    .foregroundStyle(Color(.weak))
            }
            
            Text(binding.state.uuid.uuidString)
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
            return Previewable(model, describing: state.debugDescription)
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
