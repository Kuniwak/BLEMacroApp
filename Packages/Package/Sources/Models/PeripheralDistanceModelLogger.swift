import Combine
import Logger


public final actor PeripheralDistanceModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing peripheralDistanceModel: any PeripheralDistanceModelProtocol, loggingBy logger: any LoggerProtocol) {
        peripheralDistanceModel.stateDidChange
            .sink { state in
                logger.debug("PeripheralDistanceModel#stateDidChange: \(state)")
            }
            .store(in: &cancellables)
    }
}
