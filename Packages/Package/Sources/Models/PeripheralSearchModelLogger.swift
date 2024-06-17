import Combine
import Logger


public actor PeripheralSearchModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing searchModel: any PeripheralSearchModelProtocol, loggingBy logger: any LoggerProtocol) {
        searchModel.stateDidUpdate
            .sink { state in
                logger.debug("PeripheralSearchModel#stateDidUpdate: \(state)")
            }
            .store(in: &cancellables)
        
        searchModel.searchQuery
            .sink { query in
                logger.debug("PeripheralSearchModel#searchQuery: \(query)")
            }
            .store(in: &cancellables)
    }
}
