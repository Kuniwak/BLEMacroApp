import Testing
import ConcurrentCombine
import CoreBluetoothStub
import Models


@Test
private func testInit() async throws {
    let centralManger = StubCentralManager()
    let discovery = PeripheralDiscoveryModel(observing: centralManger)
    let recorder = Recorder(observing: discovery.stateDidChange)
    
    let actual = try await recorder.values(timeout: 1)
    let expected: [PeripheralDiscoveryModelState] = [.idle]
    #expect(actual == expected)
}
