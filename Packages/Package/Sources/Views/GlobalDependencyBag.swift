import CloudKit
import Logger


public struct GlobalDependencyBag {
    public let logger: any LoggerProtocol
}


extension GlobalDependencyBag {
    public static func makeStub() -> GlobalDependencyBag {
        GlobalDependencyBag(
            logger: NullLogger()
        )
    }
}
