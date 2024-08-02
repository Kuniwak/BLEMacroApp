import os
import SwiftUI
import Logger
import ViewFoundation
import Views
import Documents

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
    public var body: some Scene {
        DocumentGroup(newDocument: BLEMacroDocument()) { file in
            RootView(logConfigurations: .default)
        }
    }
}
#endif
