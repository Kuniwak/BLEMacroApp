import SwiftUI
import ViewFoundation
import Models
import ModelStubs
import PreviewHelper


public struct DescriptorRow: View {
    @StateObject private var binding: ViewBinding<DescriptorModelState, AnyDescriptorModel>
    
    
    public init(observing model: any DescriptorModelProtocol) {
        self._binding = StateObject(wrappedValue: ViewBinding(source: model.eraseToAny()))
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
