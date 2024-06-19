import Combine
import SwiftUI
import ConcurrentCombine



public class ConcurrentValueSubjectBinding<Value> {
    public private(set) var binding: Binding<Value?>! = nil
    private var cancellables = Set<AnyCancellable>()
    private var projected: Value? = nil
    
    
    public init(_ subject: ConcurrentValueSubject<Value, Never>) {
        subject
            .sink { [weak self] value in
                guard let self else { return }
                self.projected = value
            }
            .store(in: &cancellables)
        
        self.binding = Binding(
            get: { [weak self] in self?.projected },
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
