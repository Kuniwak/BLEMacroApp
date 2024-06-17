import Combine
import Logger


public class PeripheralModelLogger {
    private var cancellables = Set<AnyCancellable>()


    public init(observing peripheralModel: any PeripheralModelProtocol, loggingBy logger: any LoggerProtocol) {
        peripheralModel.stateDidUpdate
            .sink { state in
                logger.debug("PeripheralModel#stateDidUpdate: \(state)")
            }
            .store(in: &cancellables)
    }
}
