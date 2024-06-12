import Combine
import Logger


public actor DescriptorModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing descriptorModel: any DescriptorModelProtocol, loggingBy logger: any LoggerProtocol) {
        descriptorModel.stateDidChange
            .sink { state in
                logger.debug("DescriptorModel#stateDidChange: \(state)")
            }
            .store(in: &cancellables)
    }
}
