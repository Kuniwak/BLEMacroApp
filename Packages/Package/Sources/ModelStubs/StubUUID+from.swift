import Foundation
import CoreBluetoothStub


extension StubUUID {
    public static func from(byte: UInt8) -> UUID {
        UUID(uuid: (
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, byte
        ))
    }
}
