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
}


@Test(arguments: [
//    TestCase(
//        discoveryState: .idle(requestedDiscovery: false),
//        centralManagerState: .unknown,
//        action: nil,
//        expected: [.idle(requestedDiscovery: false)]
//    ),
    TestCase(
        discoveryState: .idle(requestedDiscovery: false),
        centralManagerState: .unknown,
        action: { _, discovery async in await discovery.startScan() },
        expected: [
            .idle(requestedDiscovery: false),
            .idle(requestedDiscovery: true),
        ]
    ),
    TestCase(
        discoveryState: .idle(requestedDiscovery: false),
        centralManagerState: .unknown,
        action: { centralManager, _ in centralManager.didUpdateStateSubject.value = .poweredOn },
        expected: [
            .idle(requestedDiscovery: true),
            .discovering(nil),
        ]
    ),
    TestCase(
        discoveryState: .ready,
        centralManagerState: .poweredOn,
        action: { _, discovery in await discovery.startScan() },
        expected: [.ready, .discovering(nil)]
    ),
])
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
    #expect(actual == testCase.expected)
}
