import os
import Logger


public struct LogConfigurations: Equatable, Sendable {
    public let severity: LogSeverity
    public let app: OSLog
    public let ble: OSLog
    
    
    public init(severity: LogSeverity, app: OSLog, ble: OSLog) {
        self.severity = severity
        self.app = app
        self.ble = ble
    }
    
    
#if DEBUG
    public static let `default` = LogConfigurations(
        severity: .debug,
        app: OSLog(subsystem: "com.kuniwak.BLEMacroApp", category: "BLEApp"),
        ble: OSLog(subsystem: "com.kuniwak.BLEMacroApp.BLE", category: "BLE")
    )
#else
    public static let `default` = LogConfigurations(
        severity: .info,
        app: OSLog(subsystem: "com.kuniwak.BLEMacroApp", category: "BLEApp"),
        ble: OSLog(subsystem: "com.kuniwak.BLEMacroApp.BLE", category: "BLE")
    )
#endif
}
