import Testing
import CoreBluetooth
import ConcurrentCombine
import CoreBluetoothStub
import Models
import ModelStubs


private struct TestCase {
    let discoveryState: PeripheralDiscoveryModelState
    let centralManagerState: CBManagerState
    let action: ((StubSendableCentralManager, PeripheralDiscoveryModel) -> Void)?
    let expected: [PeripheralDiscoveryModelState]
    let sourceLocation: SourceLocation
}


private func testCases() -> [String: TestCase] {
    return [
        "t0": TestCase(
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: nil,
            expected: [.idle(requestedDiscovery: false)],
            sourceLocation: SourceLocation()
        ),
        "t1": TestCase(
            discoveryState: .idle(requestedDiscovery: true),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOn },
            expected: [
                .idle(requestedDiscovery: true),
                .discovering([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        "t2": TestCase(
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { _, discovery in discovery.startScan() },
            expected: [
                .idle(requestedDiscovery: false),
                .idle(requestedDiscovery: true),
            ],
            sourceLocation: SourceLocation()
        ),
        "t3": TestCase(
            discoveryState: .ready,
            centralManagerState: .poweredOn,
            action: { _, discovery in discovery.startScan() },
            expected: [
                .ready,
                .discovering([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        "t4": TestCase(
            discoveryState: .idle(requestedDiscovery: true),
            centralManagerState: .poweredOn,
            action: { centralmanager, _ in centralmanager.didUpdateStateSubject.value = .poweredOn },
            expected: [
                .idle(requestedDiscovery: true),
                .discovering([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        "t5": TestCase(
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
        "t6": TestCase(
            discoveryState: .discovering([], []),
            centralManagerState: .poweredOn,
            action: { _, discoveryModel in discoveryModel.stopScan() },
            expected: [
                .discovering([], []),
                .discovered([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        "t7": TestCase(
            discoveryState: .discovered([], []),
            centralManagerState: .poweredOn,
            action: { _, discoveryModel in discoveryModel.startScan() },
            expected: [
                .discovered([], []),
                .discovering([], []),
            ],
            sourceLocation: SourceLocation()
        ),
        "t8": TestCase(
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .unsupported },
            expected: [
                .idle(requestedDiscovery: false),
                .discoveryFailed(.unsupported),
            ],
            sourceLocation: SourceLocation()
        ),
        "t9": TestCase(
            discoveryState: .idle(requestedDiscovery: true),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .unsupported },
            expected: [
                .idle(requestedDiscovery: true),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        "t10": TestCase(
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .idle(requestedDiscovery: false),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        "t11": TestCase(
            discoveryState: .idle(requestedDiscovery: true),
            centralManagerState: .unknown,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .idle(requestedDiscovery: true),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        "t12": TestCase(
            discoveryState: .ready,
            centralManagerState: .poweredOn,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .ready,
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        "t13": TestCase(
            discoveryState: .discovering([], []),
            centralManagerState: .poweredOn,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .discovering([], []),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        "t14": TestCase(
            discoveryState: .discovered([], []),
            centralManagerState: .poweredOn,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .discovered([], []),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        "t15": TestCase(
            discoveryState: .discoveryFailed(.unauthorized),
            centralManagerState: .poweredOff,
            action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .discoveryFailed(.unauthorized),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
        "t16": TestCase(
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
private func testPeripheralDiscoveryModel(pair: (String, TestCase)) async throws {
    let (label, testCase) = pair
    let centralManager = StubSendableCentralManager(state: testCase.centralManagerState)
    let discovery = PeripheralDiscoveryModel(observing: centralManager, startsWith: testCase.discoveryState)
    let recorder = Recorder(observing: discovery.stateDidChange.prefix(testCase.expected.count))
    
    if let action = testCase.action {
        action(centralManager, discovery)
    }
    
    let actual = try await recorder.values(timeout: 1)
    #expect(actual == testCase.expected, .init(rawValue: label), sourceLocation: testCase.sourceLocation)
}
