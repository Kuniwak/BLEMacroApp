import Combine
import Logger


public final actor ServiceModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing serviceModel: any ServiceModelProtocol, loggingBy logger: any LoggerProtocol) {
        serviceModel.stateDidChange
            .sink { state in
                logger.debug("ServiceModel#stateDidChange: \(state)")
            }
            .store(in: &cancellables)
    }
}
