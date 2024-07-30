import Testing
import CoreBluetooth
import ConcurrentCombine
import CoreBluetoothStub
import Models
import ModelStubs
import MirrorDiffKit


private struct TestError: Error, CustomStringConvertible {
    let description: String = "TEST"
}


private struct TestCase: CustomStringConvertible {
    let description: String
    let connection: ConnectionModelState
    let action: ((ConnectionModel, StubSendableCentralManager) -> Void)?
    let expected: [ConnectionModelState]
    let sourceLocation: SourceLocation
    
    public init(
        description: String,
        connection: ConnectionModelState,
        action: ((ConnectionModel, StubSendableCentralManager) -> Void)? = nil,
        expected: [ConnectionModelState],
        sourceLocation: SourceLocation
    ) {
        self.description = description
        self.connection = connection
        self.action = action
        self.expected = expected
        self.sourceLocation = sourceLocation
    }
}


private func testCases() -> [TestCase] {
    return [
        TestCase(
            description: "t1",
            connection: .initialState(isConnectable: false),
            expected: [.notConnectable],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t2",
            connection: .initialState(isConnectable: true),
            expected: [.disconnected],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t3",
            connection: .disconnected,
            action: { connection, _ in connection.connect() },
            expected: [.disconnected, .connecting],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "refuse disconnect on disconnected",
            connection: .disconnected,
            action: { connection, _ in connection.disconnect() },
            expected: [.disconnected, .disconnected],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "refuse connect on connecting",
            connection: .connecting,
            action: { connection, _ in connection.connect() },
            expected: [.connecting, .connecting],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "refuse disconnect on connecting",
            connection: .connecting,
            action: { connection, _ in connection.connect() },
            expected: [.connecting, .connecting],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t4",
            connection: .connecting,
            action: { _, peripheral in peripheral.didConnectPeripheralSubject.send(StubPeripheral()) },
            expected: [.connecting, .connected],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t5",
            connection: .connecting,
            action: { _, peripheral in peripheral.didFailToConnectPeripheralSubject.send((peripheral: StubPeripheral(), error: TestError())) },
            expected: [.connecting, .connectionFailed(.init(description: "TEST"))],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "refuse connect connected",
            connection: .connected,
            action: { connection, _ in connection.connect() },
            expected: [.connected, .connected],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t6",
            connection: .connectionFailed(.init(description: "TEST")),
            action: { connection, _ in connection.connect() },
            expected: [.connectionFailed(.init(description: "TEST")), .connecting],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t7",
            connection: .connected,
            action: { connection, _ in connection.disconnect() },
            expected: [.connected, .disconnecting],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t8",
            connection: .disconnecting,
            action: { _, peripheral in peripheral.didDisconnectPeripheralSubject.send((peripheral: StubPeripheral(), error: nil)) },
            expected: [.disconnecting, .disconnected],
            sourceLocation: SourceLocation()
        ),
    ]
}


@Test(arguments: testCases())
private func testConnectionModel(testCase: TestCase) async throws {
    let centralManager = StubSendableCentralManager(state: .poweredOn)
    let connection = ConnectionModel(
        centralManager: centralManager,
        peripheral: StubPeripheral(),
        initialState: testCase.connection
    )
    let recorder = Recorder(observing: connection.stateDidChange.prefix(testCase.expected.count))
    
    if let action = testCase.action {
        action(connection, centralManager)
    }
    
    let actual = try await recorder.values(timeout: 1)
    #expect(actual == testCase.expected, sourceLocation: testCase.sourceLocation)
}
