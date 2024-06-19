import Combine
import Logger


public actor CharacteristicModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing characteristicModel: any CharacteristicModelProtocol, loggingBy logger: any LoggerProtocol) {
        characteristicModel.stateDidChange
            .sink { state in
                logger.debug("CharacteristicModel#stateDidChange: \(state)")
            }
            .store(in: &cancellables)
    }
}
