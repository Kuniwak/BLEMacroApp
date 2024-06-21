import Testing
import XCTest
import CoreBluetooth
import ConcurrentCombine
import CoreBluetoothStub
import Models


private struct TestCase {
    let discoveryState: PeripheralDiscoveryModelState
    let centralManagerState: CBManagerState
    let action: ((StubCentralManager, PeripheralDiscoveryModel) async -> Void)?
    let expected: [PeripheralDiscoveryModelState]
    let sourceLocation: SourceLocation
}


private func testCases() -> [TestCase]{
    return [
        TestCase(
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: nil,
            expected: [.idle(requestedDiscovery: false)],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { _, discovery async in await discovery.startScan() },
            expected: [
                .idle(requestedDiscovery: false),
                .idle(requestedDiscovery: true),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            discoveryState: .idle(requestedDiscovery: true),
            centralManagerState: .unknown,
            action: { centralManager, _ async in centralManager.didUpdateStateSubject.value = .poweredOn },
            expected: [
                .idle(requestedDiscovery: true),
                .discovering([]),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            discoveryState: .ready,
            centralManagerState: .poweredOn,
            action: { _, discovery async in await discovery.startScan() },
            expected: [
                .ready,
                .discovering([]),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            discoveryState: .ready,
            centralManagerState: .poweredOn,
            action: { _, discovery async in await discovery.startScan() },
            expected: [
                .ready,
                .discovering([]),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { centralManager, _ async in centralManager.didUpdateStateSubject.value = .unsupported },
            expected: [
                .idle(requestedDiscovery: false),
                .discoveryFailed(.unsupported),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { centralManager, _ async in centralManager.didUpdateStateSubject.value = .unauthorized },
            expected: [
                .idle(requestedDiscovery: false),
                .discoveryFailed(.unauthorized),
            ],
            sourceLocation: SourceLocation()
        ),
        TestCase(
            discoveryState: .idle(requestedDiscovery: false),
            centralManagerState: .unknown,
            action: { centralManager, _ async in centralManager.didUpdateStateSubject.value = .poweredOff },
            expected: [
                .idle(requestedDiscovery: false),
                .discoveryFailed(.powerOff),
            ],
            sourceLocation: SourceLocation()
        ),
    ]
}


@Test(arguments: testCases())
private func test(testCase: TestCase) async throws {
    let centralManager = StubCentralManager(state: testCase.centralManagerState)
    let discovery = PeripheralDiscoveryModel(observing: centralManager, startsWith: testCase.discoveryState)
    let recorder = Recorder(observing: discovery.stateDidChange.prefix(testCase.expected.count))
    
    if let action = testCase.action {
        Task {
            await action(centralManager, discovery)
        }
    }
    
    let actual = try await recorder.values(timeout: 1)
    #expect(actual == testCase.expected, sourceLocation: testCase.sourceLocation)
}
