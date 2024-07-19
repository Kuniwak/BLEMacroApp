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
    private let discoveryModel: any PeripheralDiscoveryModelProtocol
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
            options: [CBCentralManagerOptionShowPowerAlertKey: true],
            severity: severity
        )
        
        let discoveryModel = PeripheralDiscoveryModel(observing: centralManager, startsWith: .initialState())
        self.discoveryModel = discoveryModel
        
        let searchModel = PeripheralSearchModel(
            observing: discoveryModel,
            initialSearchQuery: SearchQuery(rawValue: "")
        )
        self.searchModel = searchModel
        self.binding = ViewBinding(source: searchModel.eraseToAny())
    }
    
    
    public init(discoveryModel: any PeripheralDiscoveryModelProtocol, searchModel: any PeripheralSearchModelProtocol, logger: any LoggerProtocol) {
        self.searchModel = searchModel
        self.discoveryModel = discoveryModel
        self.binding = ViewBinding(source: searchModel.eraseToAny())
        self.logger = logger
    }
    
    
    public var body: some Scene {
        WindowGroup {
            PeripheralsView(observing: searchModel, loggingBy: logger)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                discoveryModel.refreshState()
            default:
                discoveryModel.stopScan()
            }
        }
    }
}
#endif
