import Combine


extension Publisher where Failure == Never {
    public func mapAsync<NewOutput>(_ values: @escaping (Output) async -> NewOutput) -> some Publisher<NewOutput, Never> {
        map { collection in
            Future<NewOutput, Never> { promise in
                Task {
                    promise(.success(await values(collection)))
                }
            }
        }
        .switchToLatest()
    }
}
