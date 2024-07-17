import Combine
import Logger


public final actor ConnectableDescriptorModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing connectableDescriptorModel: any ConnectableDescriptorModelProtocol, loggingBy logger: any LoggerProtocol) {
        connectableDescriptorModel.stateDidChange
            .sink { state in
                logger.debug("ConnectableDescriptorModel#stateDidChange: \(state.description)")
            }
            .store(in: &cancellables)
    }
}
