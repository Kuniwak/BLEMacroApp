import Combine
import Logger


public class DescriptorModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing descriptorModel: any DescriptorModelProtocol, loggingBy logger: any LoggerProtocol) {
        descriptorModel.stateDidUpdate
            .sink { state in
                logger.debug("DescriptorModel#stateDidUpdate: \(state)")
            }
            .store(in: &cancellables)
    }
}
