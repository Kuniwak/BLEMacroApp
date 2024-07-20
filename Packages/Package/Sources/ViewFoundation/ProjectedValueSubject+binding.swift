import Combine
import SwiftUI
import ConcurrentCombine



public class ProjectedValueSubjectBinding<Value> {
    private var cancellables = Set<AnyCancellable>()
    private var subject: ConcurrentValueSubject<Value, Never>
    
    
    public init(_ subject: ConcurrentValueSubject<Value, Never>) {
        self.subject = subject
    }
    
    
    public func mapBind<NewValue>(_ get: @escaping (Value) -> (NewValue), _ set: @escaping (NewValue) -> (Value)) -> Binding<NewValue> {
        Binding(
            get: { [self] in get(self.subject.value) },
            set: { [self] newValue in
                Task {
                    await self.subject.change { value in
                        return set(newValue)
                    }
                }
            }
        )
    }
    
    
    public func bind() -> Binding<Value> {
        Binding(
            get: { [self] in self.subject.value },
            set: { [self] newValue in
                Task {
                    await self.subject.change { _ in
                        return newValue
                    }
                }
            }
        )
    }
}
