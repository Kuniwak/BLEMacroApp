import Combine
import Logger


public final actor DescriptorModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing descriptorModel: any DescriptorModelProtocol, loggingBy logger: any LoggerProtocol) {
        descriptorModel.stateDidChange
            .sink { state in
                if state.isFailed {
                    logger.notice("DescriptorModel#stateDidChange: \(state.description)")
                } else {
                    logger.debug("DescriptorModel#stateDidChange: \(state.description)")
                }
            }
            .store(in: &cancellables)
    }
}
