import SwiftUI
import CoreBluetooth
import CoreBluetoothTestable
import SFSymbol
import Models
import ModelStubs
import ViewFoundation
import Logger



public struct RootView: View {
    @StateObject private var binding: ViewBinding<PeripheralSearchModelState, AnyPeripheralSearchModel>
    @Environment(\.scenePhase) private var scenePhase
    private let searchModel: any PeripheralSearchModelProtocol
    private let deps: GlobalDependencyBag
    
    
    public init(
        searchModel: any PeripheralSearchModelProtocol,
        holding deps: GlobalDependencyBag
    ) {
        self.searchModel = searchModel
        self.deps = deps
        self._binding = StateObject(wrappedValue: ViewBinding(source: searchModel.eraseToAny()))
    }
    
    
    public init(logConfigurations: LogConfigurations) {
        self.init(
            searchModel: PeripheralSearchModel(
                observing: PeripheralDiscoveryModel(
                    observing: SendableCentralManager(
                        options: [
                            CBCentralManagerOptionShowPowerAlertKey: true,
                            CBCentralManagerScanOptionAllowDuplicatesKey: false,
                        ],
                        loggingBy: Logger(
                            severity: logConfigurations.severity,
                            writer: OSLogWriter(logConfigurations.ble)
                        )
                    ),
                    startsWith: .initialState()
                ),
                initialSearchQuery: SearchQuery(rawValue: "")
            ),
            deps: GlobalDependencyBag(
                logger: Logger(
                    severity: logConfigurations.severity,
                    writer: OSLogWriter(logConfigurations.app)
                )
                )
    )
    }

    
    public var body: some View {
        TabView {
            PeripheralSearchView(
                observing: searchModel,
                loggingBy: deps.logger
            )
            .tabItem {
                VStack {
                    Image(systemName: SFSymbol5.Antenna.radiowavesLeftAndRightCircleFill.rawValue)
                    Text("Peripherals")
                }
            }
            
            MacroView()
                .tabItem {
                    VStack {
                        Image(systemName: SFSymbol5.Play.circleFill.rawValue)
                        Text("Macros")
                    }
                }
        }
    }
}


#Preview {
    RootView(searchModel: StubPeripheralSearchModel(), logger: NullLogger())
}
