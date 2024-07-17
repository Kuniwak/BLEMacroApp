import Logger
import Models
import ModelStubs
import Logger


public struct DependencyBag {
    public let connectionModel: any ConnectionModelProtocol
    public let logger: any LoggerProtocol
}


extension DependencyBag {
    public static func makeStub() -> DependencyBag {
        DependencyBag(
            connectionModel: StubConnectionModel(),
            logger: NullLogger()
        )
    }
}
