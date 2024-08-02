import Logger
import Models
import ModelStubs
import Logger


public struct PeripheralDependencyBag {
    public let connectionModel: any ConnectionModelProtocol
    public let global: GlobalDependencyBag
    
    
    public init(
        connectionModel: any ConnectionModelProtocol,
        global: GlobalDependencyBag
    ) {
        self.connectionModel = connectionModel
        self.global = global
    }
}


extension PeripheralDependencyBag {
    public static func makeStub() -> PeripheralDependencyBag {
        PeripheralDependencyBag(
            connectionModel: StubConnectionModel(),
            global: GlobalDependencyBag.makeStub()
        )
    }
}
