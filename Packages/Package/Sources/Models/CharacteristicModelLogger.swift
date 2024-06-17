import Combine
import Logger


public class CharacteristicModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing characteristicModel: any CharacteristicModelProtocol, loggingBy logger: any LoggerProtocol) {
        characteristicModel.stateDidUpdate
            .sink { state in
                logger.debug("CharacteristicModel#stateDidUpdate: \(state)")
            }
            .store(in: &cancellables)
    }
}
