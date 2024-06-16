import SwiftUI
import os
import CoreBluetooth
import CoreBluetoothTestable
import Logger
import Models
import Views

// NOTE: The app gets initialized even during testing, which can lead to performance overhead.
#if canImport(XCTest)
@main
public struct BLEMacroApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Testing...")
        }
    }
}
#else
@main
public struct BLEMacroApp: App {
    @ObservedObject private var model: AnyPeripheralSearchModel
    private let modelLogger: PeripheralSearchModelLogger
    
    
    public init() {
#if DEBUG
        let severity: LogSeverity = .debug
#else
        let severity: LogSeverity = .info
#endif
        let logger: any LoggerProtocol = Logger(severity: severity, writer: OSLogWriter(OSLog(subsystem: "com.kuniwak.BLEMacroApp", category: "BLE")))
        let centralManager = CentralManager(
            options: [CBCentralManagerOptionShowPowerAlertKey: true],
            loggingBy: Logger(severity: severity, writer: OSLogWriter(OSLog(subsystem: "com.kuniwak.BLEMacro", category: "BLE")))
        )
        
        let model = PeripheralSearchModel(
            observing: PeripheralDiscoveryModel(observing: centralManager),
            initialSearchQuery: ""
        )
        self.model = model.eraseToAny()

        self.modelLogger = PeripheralSearchModelLogger(
            observing: model,
            loggingBy: logger
        )
    }
    
    
    public init(model: any PeripheralSearchModelProtocol, logger: any LoggerProtocol) {
        self.model = model.eraseToAny()

        self.modelLogger = PeripheralSearchModelLogger(
            observing: model,
            loggingBy: logger
        )
    }
    
    
    public var body: some Scene {
        WindowGroup {
            BLEDevicesView(model: model)
        }
    }
}
#endif
