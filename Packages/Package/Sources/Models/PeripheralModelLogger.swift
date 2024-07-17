import Combine
import Logger


public final actor PeripheralModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing peripheralModel: any PeripheralModelProtocol, loggingBy logger: any LoggerProtocol) {
        peripheralModel.stateDidChange
            .sink { state in
                logger.debug("PeripheralModel#stateDidChange: \(state)")
            }
            .store(in: &cancellables)
    }
}
