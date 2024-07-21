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
internal struct BLEMacroApp: App {
    @ObservedObject private var binding: ViewBinding<PeripheralSearchModelState, AnyPeripheralSearchModel>
    @Environment(\.scenePhase) private var scenePhase
    private let searchModel: any PeripheralSearchModelProtocol
    private let logger: any LoggerProtocol
    
    
    public init() {
#if DEBUG
        let severity: LogSeverity = .debug
#else
        let severity: LogSeverity = .info
#endif
        let logger: any LoggerProtocol = Logger(severity: severity, writer: OSLogWriter(OSLog(subsystem: "com.kuniwak.BLEMacroApp", category: "BLE")))
        self.logger = logger
        
        let centralManager = SendableCentralManager(
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true,
                CBCentralManagerScanOptionAllowDuplicatesKey: false,
            ],
            severity: severity
        )
        
        let searchModel = PeripheralSearchModel(
            observing: PeripheralDiscoveryModel(observing: centralManager, startsWith: .initialState()),
            initialSearchQuery: SearchQuery(rawValue: "")
        )
        self.searchModel = searchModel
        self.binding = ViewBinding(source: searchModel.eraseToAny())
    }
    
    
    public init(searchModel: any PeripheralSearchModelProtocol, logger: any LoggerProtocol) {
        self.searchModel = searchModel
        self.binding = ViewBinding(source: searchModel.eraseToAny())
        self.logger = logger
    }
    
    
    public var body: some Scene {
        WindowGroup {
            PeripheralSearchView(observing: searchModel, loggingBy: logger)
        }
    }
}
#endif
