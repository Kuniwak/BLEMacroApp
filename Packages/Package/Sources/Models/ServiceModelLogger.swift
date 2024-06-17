import Combine
import Logger


public class ServiceModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing serviceModel: any ServiceModelProtocol, loggingBy logger: any LoggerProtocol) {
        serviceModel.stateDidUpdate
            .sink { state in
                logger.debug("ServiceModel#stateDidUpdate: \(state)")
            }
            .store(in: &cancellables)
    }
}
