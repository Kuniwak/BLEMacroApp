import Testing
import CoreBluetooth
import ConcurrentCombine
import CoreBluetoothStub
import Models
import ModelStubs
import MirrorDiffKit


private struct TestCase: CustomStringConvertible {
    let description: String
    let discoveryState: PeripheralDiscoveryModelState
    let centralManagerState: CBManagerState
    let action: ((StubSendableCentralManager, PeripheralDiscoveryModel) -> Void)?
    let expected: [PeripheralDiscoveryModelState]
    let sourceLocation: SourceLocation
}


private func testCases() -> [TestCase] {
    return [
        TestCase(
            description: "t0",
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: nil,
            expected: [.idle(requestedDiscovery: false)],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t1",
            discoveryState: .idle(requestedDiscovery: true),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOn },
            expected: [
                .idle(requestedDiscovery: true),
                .discovering([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t2",
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { _, discovery in discovery.startScan() },
            expected: [
                .idle(requestedDiscovery: false),
                .idle(requestedDiscovery: true),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t3",
            discoveryState: .ready,
            centralManagerState: .poweredOn,
            action: { _, discovery in discovery.startScan() },
            expected: [
                .ready,
                .discovering([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t4",
            discoveryState: .idle(requestedDiscovery: true),
            centralManagerState: .poweredOn,
            action: { centralmanager, _ in centralmanager.didUpdateStateSubject.value = .poweredOn },
            expected: [
                .idle(requestedDiscovery: true),
                .discovering([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t5",
            discoveryState: .discovering([], []),
            centralManagerState: .poweredOn,
            action: { centralmanager, _ in
                centralmanager.didDiscoverPeripheralSubject
                    .send((
                        peripheral: StubPeripheral(
                            identifier: StubUUID.from(byte: 1),
                            name: "Example",
                            state: .disconnected
                        ),
                        advertisementData: [:],
                        rssi: -50
                    ))
            },
            expected: [
                .discovering([], []),
                .discovering([
                    StubPeripheralModel(state: .init(
                        uuid: StubUUID.from(byte: 1),
                        name: .success("Example"),
                        rssi: .success(-50),
                        manufacturerData: nil,
                        advertisementData: [:],
                        connection: .disconnected,
                        discovery: .notDiscoveredYet
                    )).eraseToAny(),
                ], [StubUUID.from(byte: 1)]),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t6",
            discoveryState: .discovering([], []),
            centralManagerState: .poweredOn,
            action: { _, discoveryModel in discoveryModel.stopScan() },
            expected: [
                .discovering([], []),
                .discovered([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t7",
            discoveryState: .discovered([], []),
            centralManagerState: .poweredOn,
            action: { _, discoveryModel in discoveryModel.startScan() },
            expected: [
                .discovered([], []),
                .discovering([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t8",
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .unsupported },
            expected: [
                .idle(requestedDiscovery: false),
                .discoveryFailed(.unsupported),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t9",
            discoveryState: .idle(requestedDiscovery: true),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .unsupported },
            expected: [
                .idle(requestedDiscovery: true),
                .discoveryFailed(.unsupported),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t10",
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .idle(requestedDiscovery: false),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t11",
            discoveryState: .idle(requestedDiscovery: true),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .idle(requestedDiscovery: true),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t12",
            discoveryState: .ready,
            centralManagerState: .poweredOn,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .ready,
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t13",
            discoveryState: .discovering([], []),
            centralManagerState: .poweredOn,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .discovering([], []),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t14",
            discoveryState: .discovered([], []),
            centralManagerState: .poweredOn,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .discovered([], []),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t15",
            discoveryState: .discoveryFailed(.unauthorized),
            centralManagerState: .poweredOff,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .discoveryFailed(.unauthorized),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            description: "t16",
            discoveryState: .discoveryFailed(.unauthorized),
            centralManagerState: .poweredOff,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOn },
            expected: [
                .discoveryFailed(.unauthorized),
                .ready
            ],
            sourceLocation: SourceLocation()
        ),
    ]
}


@Test(arguments: testCases())
private func testPeripheralDiscoveryModel(testCase: TestCase) async throws {
    let centralManager = StubSendableCentralManager(state: testCase.centralManagerState)
    let discovery = PeripheralDiscoveryModel(observing: centralManager, startsWith: testCase.discoveryState)
    let recorder = Recorder(observing: discovery.stateDidChange.prefix(testCase.expected.count))
    
    if let action = testCase.action {
        action(centralManager, discovery)
    }
    
    let actual = try await recorder.values(timeout: 1)
    #expect(actual == testCase.expected, sourceLocation: testCase.sourceLocation)
}
