import Combine
import SwiftUI


extension CurrentValueSubject {
  public func binding() -> Binding<Output> {
    Binding(get: {
      self.value
    }, set: {
      self.send($0)
    })
  }
}
