// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Package",
    platforms: [
        .iOS(.v15),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Models",
            targets: ["Models"]
        ),
        .library(
            name: "Views",
            targets: ["Views"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Kuniwak/swift-logger.git", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/Kuniwak/swift-ble-assigned-numbers.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Kuniwak/core-bluetooth-testable.git", .upToNextMajor(from: "4.0.1")),
        .package(url: "https://github.com/Kuniwak/swift-ble-macro.git", .upToNextMajor(from: "2.1.1")),
        .package(url: "https://github.com/cezheng/Fuzi.git", .upToNextMajor(from: "3.1.3")),
        .package(url: "https://github.com/Kuniwak/MirrorDiffKit.git", .upToNextMajor(from: "6.0.0")),
    ],
    targets: [
        .target(
            name: "Catalogs",
            dependencies: [
                .bleAssignedNumbers,
            ]
        ),
        .target(
            name: "Models",
            dependencies: [
                .logger,
                .fuzi,
                .coreBluetoothTestable,
                .bleAssignedNumbers,
                .bleMacro,
                .bleMacroCompiler,
                .bleCommand,
                .bleInterpreter,
                .bleModel,
                .catalogs,
            ]
        ),
        .target(
            name: "ModelStubs",
            dependencies: [
                .models,
                .bleModelStub,
                .coreBluetoothTestable,
                .coreBluetoothStub,
                .mirrorDiffKit,
            ]
        ),
        .testTarget(
            name: "ModelTests",
            dependencies: [
                .logger,
                .coreBluetoothTestable,
                .models,
                .mirrorDiffKit,
            ]
        ),
        .target(
            name: "Views",
            dependencies: [
                .previewHelper,
                .models,
                .modelStubs,
                .coreBluetoothTestable,
                .coreBluetoothStub,
            ]
        ),
        .target(name: "PreviewHelper"),
    ]
)

private extension Target.Dependency {
    static let previewHelper: Self = "PreviewHelper"
    static let catalogs: Self = "Catalogs"
    static let models: Self = "Models"
    static let modelStubs: Self = "ModelStubs"
    static let logger: Self = .product(name: "Logger", package: "swift-logger")
    static let coreBluetoothTestable: Self = .product(name: "CoreBluetoothTestable", package: "core-bluetooth-testable")
    static let coreBluetoothStub: Self = .product(name: "CoreBluetoothStub", package: "core-bluetooth-testable")
    static let bleAssignedNumbers: Self = .product(name: "BLEAssignedNumbers", package: "swift-ble-assigned-numbers")
    static let bleMacro: Self = .product(name: "BLEMacro", package: "swift-ble-macro")
    static let bleCommand: Self = .product(name: "BLECommand", package: "swift-ble-macro")
    static let bleMacroCompiler: Self = .product(name: "BLEMacroCompiler", package: "swift-ble-macro")
    static let bleInterpreter: Self = .product(name: "BLEInterpreter", package: "swift-ble-macro")
    static let bleModel: Self = .product(name: "BLEModel", package: "swift-ble-macro")
    static let bleModelStub: Self = .product(name: "BLEModelStub", package: "swift-ble-macro")
    static let bleInternal: Self = .product(name: "BLEInternal", package: "swift-ble-macro")
    static let mirrorDiffKit: Self = .product(name: "MirrorDiffKit", package: "MirrorDiffKit")
    static let fuzi: Self = .product(name: "Fuzi", package: "Fuzi")
}
