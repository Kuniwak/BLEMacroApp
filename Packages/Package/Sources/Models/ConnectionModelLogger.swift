import Combine
import Logger


public actor ConnectionModelLogger {
    private var cancellables = Set<AnyCancellable>()


    public init(observing connectionModel: any ConnectionModelProtocol, loggingBy logger: any LoggerProtocol) {
        connectionModel.stateDidChange
            .sink { state in
                logger.debug("ConnectionModel#stateDidChange: \(state)")
            }
            .store(in: &cancellables)
    }
}
