import Combine
import Logger


public final actor IBeaconModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing iBeaconModel: any IBeaconModelProtocol, loggingBy logger: any LoggerProtocol) {
        iBeaconModel.stateDidChange
            .sink { state in
                logger.debug("IBeaconModel#stateDidChange: \(state)")
            }
            .store(in: &cancellables)
    }
}
