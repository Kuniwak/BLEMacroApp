import Combine
import Logger


public final actor ConnectionModelLogger {
    private var cancellables = Set<AnyCancellable>()


    public init(observing connectionModel: any ConnectionModelProtocol, loggingBy logger: any LoggerProtocol) {
        connectionModel.stateDidChange
            .sink { state in
                switch state {
                case .connectionFailed(let error):
                    logger.notice("ConnectionModel#stateDidChange: \(state)")
                default:
                    logger.debug("ConnectionModel#stateDidChange: \(state)")
                }
            }
            .store(in: &cancellables)
    }
}
