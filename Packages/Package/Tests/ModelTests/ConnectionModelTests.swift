import Testing
import CoreBluetooth
import ConcurrentCombine
import CoreBluetoothStub
import Models
import ModelStubs


private struct TestError: Error, CustomStringConvertible {
    let description: String = "TEST"
}


private struct TestCase {
    let connection: ConnectionModelState
    let action: ((ConnectionModel, StubSendableCentralManager) -> Void)?
    let expected: [ConnectionModelState]
    let sourceLocation: SourceLocation
    
    public init(
        connection: ConnectionModelState,
        action: ((ConnectionModel, StubSendableCentralManager) -> Void)? = nil,
        expected: [ConnectionModelState],
        sourceLocation: SourceLocation = SourceLocation()
    ) {
        self.connection = connection
        self.action = action
        self.expected = expected
        self.sourceLocation = sourceLocation
    }
}


private func testCases() -> [String: TestCase] {
    return [
        "t1": TestCase(
            connection: .initialState(isConnectable: false),
            expected: [.notConnectable]
        ),
        "t2": TestCase(
            connection: .initialState(isConnectable: true),
            expected: [.disconnected]
        ),
        "t3": TestCase(
            connection: .disconnected,
            action: { connection, _ in connection.connect() },
            expected: [.disconnected, .connecting]
        ),
        "refuse disconnect on disconnected": TestCase(
            connection: .disconnected,
            action: { connection, _ in connection.disconnect() },
            expected: [.disconnected, .disconnected]
        ),
        "refuse connect on connecting": TestCase(
            connection: .connecting,
            action: { connection, _ in connection.connect() },
            expected: [.connecting, .connecting]
        ),
        "refuse disconnect on connecting": TestCase(
            connection: .connecting,
            action: { connection, _ in connection.connect() },
            expected: [.connecting, .connecting]
        ),
        "t4": TestCase(
            connection: .connecting,
            action: { _, peripheral in peripheral.didConnectPeripheralSubject.send(StubPeripheral()) },
            expected: [.connecting, .connected]
        ),
        "t5": TestCase(
            connection: .connecting,
            action: { _, peripheral in peripheral.didFailToConnectPeripheralSubject.send((peripheral: StubPeripheral(), error: TestError())) },
            expected: [.connecting, .connectionFailed(.init(description: "TEST"))]
        ),
        "refuse connect connected": TestCase(
            connection: .connected,
            action: { connection, _ in connection.connect() },
            expected: [.connected, .connected]
        ),
        "t6": TestCase(
            connection: .connectionFailed(.init(description: "TEST")),
            action: { connection, _ in connection.connect() },
            expected: [.connectionFailed(.init(description: "TEST")), .connecting]
        ),
        "t7": TestCase(
            connection: .connected,
            action: { connection, _ in connection.disconnect() },
            expected: [.connected, .disconnecting]
        ),
        "t8": TestCase(
            connection: .disconnecting,
            action: { _, peripheral in peripheral.didDisconnectPeripheralSubject.send((peripheral: StubPeripheral(), error: nil)) },
            expected: [.connected, .disconnecting]
        ),
    ]
}


@Test(arguments: testCases())
private func testConnectionModel(pair: (String, TestCase)) async throws {
    let (label, testCase) = pair
    let centralManager = StubSendableCentralManager(state: .poweredOn)
    let connection = ConnectionModel(
        centralManager: centralManager,
        peripheral: StubPeripheral(),
        isConnectable: testCase.connection != .notConnectable
    )
    let recorder = Recorder(observing: connection.stateDidChange.prefix(testCase.expected.count))
    
    if let action = testCase.action {
        action(connection, centralManager)
    }
    
    let actual = try await recorder.values(timeout: 1)
    #expect(actual == testCase.expected, .init(rawValue: label), sourceLocation: testCase.sourceLocation)
}
