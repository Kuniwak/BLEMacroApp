import Combine
import ModelFoundation
import Models
import CoreBluetoothStub


public final actor StubIBeaconModel: IBeaconModelProtocol {
    nonisolated public var state: State { stateDidChangeSubject.value }
    nonisolated public let stateDidChange: AnyPublisher<State, Never>
    nonisolated public let stateDidChangeSubject: CurrentValueSubject<State, Never>
    
    public init(state: State) {
        let stateDidChangeSubject = CurrentValueSubject<State, Never>(state)
        self.stateDidChangeSubject = stateDidChangeSubject
        self.stateDidChange = stateDidChangeSubject.eraseToAnyPublisher()
    }
}


extension IBeaconData {
    public static func makeStub() -> IBeaconData {
        return IBeaconData(
            type: IBeaconType(0x00, 0x00),
            proximityUUID: StubUUID.zero,
            major: IBeaconRegion(0x00, 0x00),
            minor: IBeaconRegion(0x00, 0x00),
            measuredPower: 0x00
        )
    }
    
    
    public static func makeSuccessfulStub() -> IBeaconData {
        return IBeaconData(
            type: .proximity,
            proximityUUID: StubUUID.one,
            major: IBeaconRegion(0x12, 0x34),
            minor: IBeaconRegion(0x56, 0x78),
            measuredPower: -50
        )
    }
}
