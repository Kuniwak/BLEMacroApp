import Combine
import Logger


public final actor CharacteristicModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing characteristicModel: any CharacteristicModelProtocol, loggingBy logger: any LoggerProtocol) {
        characteristicModel.stateDidChange
            .sink { state in
                if state.isFailed {
                    logger.notice("CharacteristicModel#stateDidChange: \(state)")
                } else {
                    logger.debug("CharacteristicModel#stateDidChange: \(state)")
                }
            }
            .store(in: &cancellables)
    }
}
