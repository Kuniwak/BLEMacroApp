State Machine-based MVVM Architecture
======================================
State Machine-based MVVM Architecture is an iOS/macOS application that adopts Swift's Actor-based State Machine architecture. It leverages SwiftUI, Combine, and Swift Concurrency to achieve thread-safe state management and reactive data flow.


Goals
----
We aim to minimize the total cost of future expected changes (the sum of specification writing, design, implementation, verification, and release costs for each change).

This project describes design principles in this document where feature additions can be handled by adding components (which eliminates the need to modify or retest existing components, reducing costs) and enables easy unit testing (which reduces verification costs).


Comparison with Other Architectures
--------------------------
State Machine-based MVVM has the following advantages compared to other architectures (Cocoa MVC, Classical MVC, MVVM, MVP, TCA):

* Low maintenance cost
    * Fewer dependent libraries and frameworks reduce follow-up costs (advantage over TCA)
* Easy testing
    * Models enable easy scenario-based testing and 0-switch coverage testing (advantage over Cocoa MVC)
    * Views enable easy visual testing through previews (advantage over Cocoa MVC)
* High flexibility
    * Fewer constraints allow relatively straightforward implementation of desired features (advantage over TCA)
* High reusability
    * Models provide interface parallel, making division and composition easy (advantage over Cocoa MVC)
* High readability
    * Clear responsibilities and limitations make it relatively easy to understand what goes where (advantage over MVC, MVVM, MVP)

Disadvantages are as follows:

* High design skill requirements
    * Fewer constraints leave more room for catastrophic design decisions


Model
-----
A Model is a state machine. State machines have two properties: a property that synchronously returns the current state and a Publisher property that notifies of state changes.
When a Model's state space is large, it's good practice to divide it and use interface parallel to create the intended state space.


### Model Implementation Method
All Models implement the following `StateMachineProtocol`:

```swift
public protocol StateMachineProtocol<State>: Actor {
    associatedtype State: StateProtocol
    nonisolated var state: State { get }
    var stateDidChange: AnyPublisher<State, Never> { get }
}
```

Each Model provides the following three components:

- **Protocol**: Declaration of events accepted by the state machine
- **Concrete Implementation**: Implementation that performs actual state transitions (`ExampleModel`)
- **Constant Implementation**: Stub implementation for testing and preview (`ConstantExampleModel`)


#### Code Example
##### Basic Implementation

We use `ConcurrentValueSubject` from `ConcurrentCombine` for state storage.
`ConcurrentValueSubject` is the Swift Concurrency-compatible version of `CurrentValueSubject`.

```swift
/// Protocol definition (preferably draw state transition diagram with PlantUML)
public protocol ExampleModelProtocol: StateMachineProtocol<ExampleState> {
    // Declare event trigger methods. No other methods or properties should be declared.
    // Declare as nonisolated synchronous functions without return values to immediately return control from View-side calls.
    nonisolated func eventA()
    nonisolated func eventB(param: Int)
}


/// State definition
public enum ExampleState: StateProtocol {
    // Enumerate states. May or may not have associated values.
    case state1(message: String)
    case state2(message: String)
    case state3(message: String)
    
    /// True if stable state, false otherwise.
    public var isStable: Bool {
        switch self {
        case .state1, .state3: return true
        case .state2: return false
        }
    }

    // Computed properties may be added.
    public var message: String {
        switch self {
        case .state1(let message):
            return message
        case .state2(let message):
            return message
        case .state3(let message):
            return message
        }
    }
}

/// Concrete implementation
public final actor ExampleModel: ExampleModelProtocol {
    private let stateDidChangeSubject: ConcurrentValueSubject<State>
    
    // No public properties other than state and stateDidChange should be added.
    public nonisolated var state: State { stateDidChangeSubject.state }
    public nonisolated let stateDidChange: AnyPublisher<State, Never>

    public init(startsWith initialState: State) {
        guard initialState.isStable else {
            preconditionFailure("state must be stable")
        }
        let stateDidChangeSubject = ConcurrentValueSubject<State, Never>(initialState)
        self.stateDidChangeSubject = stateDidChangeSubject
        stateDidChange = stateDidChangeSubject.eraseToAnyPubisher()
    }

    // No public methods other than event trigger methods should be added.
    
    public nonisolated func eventA() {
        Task {
            await self.eventAInternal()
        }
    }

    private func eventAInternal() async {
        // State transition by event A
    }

    public nonisolated func eventB(param: Int) {
        Task {
            await self.eventBInternal(param: param)
        }
    }

    private func eventBInternal() async {
        // State transition by event B
    }
}
```


#### Model Interface Parallel
Interface parallel of Models is achieved by creating a new wrapper model:

```swift
// Define the composed state (compose from multiple Model states)
public enum CompositeState: StateProtocol {
    case stateA(message: String)
    case stateB(value: Int)
    case stateAB(message: String, value: Int)
    case failed
    
    public var isStable: Bool {
        switch self {
        case .stateA, .stateB, .stateAB, .failed:
            return true
        }
    }
    
    // Generate composed state from ModelA and ModelB states
    public init(modelAState: ModelAState, modelBState: ModelBState) {
        switch (modelAState, modelBState) {
        case (.active(let message), .inactive):
            self = .stateA(message: message)
        case (.inactive, .active(let value)):
            self = .stateB(value: value)
        case (.active(let message), .active(let value)):
            self = .stateAB(message: message, value: value)
        case (.failed, _), (_, .failed):
            self = .failed
        default:
            self = .failed
        }
    }
}

// Wrapper Model that performs interface parallel
public final actor CompositeModel: StateMachineProtocol<CompositeState> {
    private let modelA: any ModelAProtocol
    private let modelB: any ModelBProtocol
    private var cancellables: Set<AnyCancellable> = []
    
    // Synchronously return current state
    nonisolated public var state: CompositeState {
        .init(modelAState: modelA.state, modelBState: modelB.state)
    }
    
    // Notify state changes as Publisher
    nonisolated public let stateDidChange: AnyPublisher<CompositeState, Never>
    
    public init(
        observing modelA: any ModelAProtocol,
        observing modelB: any ModelBProtocol
    ) {
        self.modelA = modelA
        self.modelB = modelB
        
        // Monitor state changes of both Models and generate composed state
        self.stateDidChange = Publishers
            .CombineLatest(
                modelA.stateDidChange,
                modelB.stateDidChange
            )
            .map { (modelAState, modelBState) in 
                CompositeState(modelAState: modelAState, modelBState: modelBState)
            }
            .eraseToAnyPublisher()
    }
    
    // Example when there are synchronized events
    nonisolated public func synchronizedEvent() {
        Task {
            await self.synchronizedEventInternal()
        }
    }
    
    private func synchronizedEventInternal() async {
        // Send the same event to both ModelA and ModelB (synchronized event)
        modelA.eventX()
        modelB.eventX()
    }
    
    // Event that affects only ModelA
    nonisolated public func eventForModelA() {
        modelA.eventA()
    }
    
    // Event that affects only ModelB
    nonisolated public func eventForModelB() {
        modelB.eventB()
    }
}
```


View
----
A View is a projection from Model state to appearance (meaning that appearance is determined when state is determined).


### View Implementation Method
State transition notifications are received via `ViewBinding`:

```swift
// ViewBinding class
public class ViewBinding<State>: ObservableObject {
    @Published public private(set) var state: State
    
    public init<StateMachine: StateMachineProtocol>(source: StateMachine) where StateMachine.State == State {
        self.state = source.state
        self.cancellable = source.stateDidChange
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)
    }
}
```


#### Basic Implementation

```swift
public class ExampleView: View {
    // Keep the Model to subscribe to. Multiple Models are acceptable if there are no events to synchronize between subscribed Models.
    private let model: any ExampleModelProtocol

    // Monitor state changes of the Model to display.
    @StateObject private var binding: ViewBinding<ExampleState>

    // Allow receiving Model from outside. This makes it easy to verify arbitrary displays by receiving constant models in tests and previews.
    public init(observing model: any ExampleModelProtocol) {
        self.model = model
        self._binding = .init(wrappedValue: .init(source: model))
    }

    public var body: View {
        Text(binding.state.message)
    }
}
```


#### Bidirectional Binding
To bring UI state from TextField, Picker, etc. into the Model layer, use `ConcurrentValueStateMachine`.

```swift
public class ExampleView: View {
    private let model: ConcurrentValueStateMachineProtocol<String>

    // Monitor state changes of the Model to display.
    @StateObject private var binding: ViewBinding<String>

    // Declare stored property for bidirectional binding.
    @Binding private var message: String

    public init(observing model: any ConcurrentValueStateMachineProtocol<ExampleState>) {
        self.model = model
        self._binding = .init(wrappedValue: .init(source: model))
        self._message = model.binding()
    }

    public var body: View {
        TextField("Message", $message)
    }
}
```


How to Add New Components
------------------------------

### 1. Adding a New Model

1. **State Definition**: Create enum that implements `StateProtocol`
2. **Protocol Definition**: Protocol that inherits from `StateMachineProtocol`
3. **Concrete Implementation**: Implement as Actor, observe other Models as needed
4. **Test Implementation**: Create `ConstantExampleModel`

### 2. Adding a New View

1. **ViewBinding Setup**: `@StateObject private var binding: ViewBinding<State>`
2. **State-Driven UI**: State-specific UI implementation with switch statement
3. **Dependency Injection**: Receive necessary Models in initializer
4. **Preview Implementation**: SwiftUI Preview using `ConstantModel`

### 3. Combining Model and View

1. **RootView Initialization**: Initialize new Models and build dependency relationships
2. **Passing to Views**: Pass Models to necessary Views
3. **ViewBinding Creation**: Set up state observation on View side
