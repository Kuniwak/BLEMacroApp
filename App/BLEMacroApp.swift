import SwiftUI
import os
import CoreBluetooth
import CoreBluetoothTestable
import Logger
import Models
import Views
import ViewFoundation

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
    @ObservedObject private var binding: ViewBinding<PeripheralSearchModelState, AnyPeripheralSearchModel>
    private let model: any PeripheralSearchModelProtocol
    private let logger: any LoggerProtocol
    
    
    public init() {
#if DEBUG
        let severity: LogSeverity = .debug
#else
        let severity: LogSeverity = .info
#endif
        let logger: any LoggerProtocol = Logger(severity: severity, writer: OSLogWriter(OSLog(subsystem: "com.kuniwak.BLEMacroApp", category: "BLE")))
        self.logger = logger
        
        let centralManager = CentralManager(
            options: [CBCentralManagerOptionShowPowerAlertKey: true],
            loggingBy: Logger(severity: severity, writer: OSLogWriter(OSLog(subsystem: "com.kuniwak.BLEMacroLibrary", category: "BLE")))
        )
        
        let model = PeripheralSearchModel(
            observing: PeripheralDiscoveryModel(observing: centralManager, startsWith: .initialState()),
            initialSearchQuery: SearchQuery(rawValue: "")
        )
        self.model = model
        self.binding = ViewBinding(source: model.eraseToAny())
    }
    
    
    public init(model: any PeripheralSearchModelProtocol, logger: any LoggerProtocol) {
        self.model = model
        self.binding = ViewBinding(source: model.eraseToAny())
        self.logger = logger
    }
    
    
    public var body: some Scene {
        WindowGroup {
            PeripheralsView(observing: model, loggingBy: logger)
        }
    }
}
#endif
