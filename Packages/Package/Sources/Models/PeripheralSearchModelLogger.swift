import Combine
import Logger


public final actor PeripheralSearchModelLogger {
    private var cancellables = Set<AnyCancellable>()
    
    
    public init(observing searchModel: any PeripheralSearchModelProtocol, loggingBy logger: any LoggerProtocol) {
        searchModel.stateDidChange
            .sink { state in
                logger.debug("PeripheralSearchModel#stateDidChange: \(state)")
            }
            .store(in: &cancellables)
        
        searchModel.searchQuery
            .sink { query in
                logger.debug("PeripheralSearchModel#searchQuery: \(query)")
            }
            .store(in: &cancellables)
    }
}
