import Combine
import SwiftUI
import ConcurrentCombine



public class ConcurrentValueSubjectBinding<Value> {
    private var cancellables = Set<AnyCancellable>()
    private var projected: Value
    private var subject: ConcurrentValueSubject<Value, Never>
    
    
    public init(_ subject: ConcurrentValueSubject<Value, Never>) {
        self.projected = subject.initialValue
        self.subject = subject
        
        subject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self else { return }
                self.projected = value
            }
            .store(in: &cancellables)
    }
    
    
    public func mapBind<NewValue>(_ get: @escaping (Value) -> (NewValue), _ set: @escaping (NewValue) -> (Value)) -> Binding<NewValue> {
        Binding(
            get: { [self] in get(self.projected) },
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
            get: { [self] in self.projected },
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
