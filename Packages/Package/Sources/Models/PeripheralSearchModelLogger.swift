import Combine
import Logger


public final actor PeripheralSearchModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing searchModel: any PeripheralSearchModelProtocol, loggingBy logger: any LoggerProtocol) {
        searchModel.stateDidChange
            .sink { state in
                if state.isFailed {
                    logger.notice("PeripheralSearchModel#stateDidChange: \(state)")
                } else {
                    logger.debug("PeripheralSearchModel#stateDidChange: \(state)")
                }
            }
            .store(in: &cancellables)
    }
}
