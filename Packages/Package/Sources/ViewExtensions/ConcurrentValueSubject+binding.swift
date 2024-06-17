import Combine
import SwiftUI
import ConcurrentCombine



public class ConcurrentValueSubjectBinding<Value> {
    public private(set) var binding: Binding<Value?>! = nil
    private var cancellables = Set<AnyCancellable>()
    private var value: Value? = nil
    
    
    public init(_ subject: ConcurrentValueSubject<Value, Never>) {
        subject
            .sink { [weak self] value in
                guard let self else { return }
                self.value = value
            }
            .store(in: &cancellables)
        
        self.binding = Binding(
            get: { [weak self] in self?.value },
            set: { newValue in
                Task {
                    await subject.change { prev in
                        guard let newValue else { return prev }
                        return newValue
                    }
                }
            }
        )
    }
}


extension ConcurrentValueSubject where Failure == Never {
    nonisolated public func binding() -> ConcurrentValueSubjectBinding<Output> {
        ConcurrentValueSubjectBinding<Output>(self)
    }
}
