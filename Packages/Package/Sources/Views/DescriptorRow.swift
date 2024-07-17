import SwiftUI
import ViewFoundation
import Models
import ModelStubs
import PreviewHelper


public struct DescriptorRow: View {
    @ObservedObject private var binding: ViewBinding<DescriptorModelState, AnyDescriptorModel>
    
    
    public init(observing model: any DescriptorModelProtocol) {
        self.binding = ViewBinding(source: model.eraseToAny())
    }
    
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let name = binding.state.name {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Color(.normal))
            } else {
                Text("(no name)")
                    .font(.headline)
                    .foregroundStyle(Color(.weak))
            }
            
            Text(binding.state.uuid.uuidString)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .foregroundStyle(Color(.weak))
        }
    }
}


#Preview {
    NavigationStack {
        List {
            let states: [DescriptorModelState] = [
                .makeStub(name: "Example"),
                .makeStub(name: nil),
            ]
            
            let wrappers: [Previewable] = states.map { state in
                Previewable(state, describing: state.debugDescription)
            }
            
            ForEach(wrappers) { wrapper in
                DescriptorRow(observing: StubDescriptorModel(state: wrapper.value))
                NavigationLink(destination: Text("TODO")) {
                    DescriptorRow(observing: StubDescriptorModel(state: wrapper.value))
                }
            }
        }
    }
}
