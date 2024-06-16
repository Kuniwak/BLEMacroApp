import SwiftUI
import os
import CoreBluetooth
import CoreBluetoothTestable
import Logger
import Models
import Views

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
        let logger: any LoggerProtocol = Logger(
            severity: severity,
            writer: OSLogWriter(OSLog(
                subsystem: "com.kuniwak.BLEMacroApp",
                category: "BLE"
            ))
        )
        let centralManager = CentralManager(
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true,
            ],
            loggingBy: logger
        )
        
        let model = PeripheralSearchModel(
            observing: PeripheralDiscoveryModel(observing: centralManager),
            initialSearchQuery: ""
        ).eraseToAny()
        self.model = model

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
