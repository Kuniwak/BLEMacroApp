import CoreBluetooth
import BLEAssignedNumbers


extension CBUUID {
    internal var uuid: UUID? {
        switch data.count {
        case 2:
            return uuid16Bits(data[0], data[1])
        case 4:
            return uuid32Bits(data[0], data[1], data[2], data[3])
        case 16:
            return UUID(uuid: (
                data[0], data[1], data[2], data[3],
                data[4], data[5], data[6], data[7],
                data[8], data[9], data[10], data[11],
                data[12], data[13], data[14], data[15]
            ))
        default:
            return nil
        }
    }
}
