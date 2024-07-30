import Logger
import Models
import ModelStubs
import Logger


public struct PeripheralDependencyBag {
    public let connectionModel: any ConnectionModelProtocol
    public let logger: any LoggerProtocol
}


extension PeripheralDependencyBag {
    public static func makeStub() -> PeripheralDependencyBag {
        PeripheralDependencyBag(
            connectionModel: StubConnectionModel(),
            logger: NullLogger()
        )
    }
}
