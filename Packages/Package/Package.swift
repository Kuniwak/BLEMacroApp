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
        .package(url: "https://github.com/Kuniwak/core-bluetooth-testable.git", .upToNextMajor(from: "2.0.1")),
        .package(url: "https://github.com/Kuniwak/swift-ble-macro.git", .upToNextMajor(from: "2.0.1")),
        .package(url: "https://github.com/cezheng/Fuzi.git", .upToNextMajor(from: "3.1.3")),
        .package(url: "https://github.com/Kuniwak/MirrorDiffKit.git", .upToNextMajor(from: "6.0.0")),
    ],
    targets: [
        .target(
            name: "Models",
            dependencies: [
                .logger,
                .coreBluetoothTetable,
                .bleAssignedNumbers,
                .bleMacro,
                .bleMacroCompiler,
                .bleCommand,
                .bleInterpreter,
                .fuzi,
            ]
        ),
        .target(
            name: "Views",
            dependencies: [
                .models,
            ]
        ),
        .testTarget(
            name: "ModelTests",
            dependencies: [
                .models,
                .mirrorDiffKit,
            ]
        ),
    ]
)

private extension Target.Dependency {
    static let models: Self = "Models"
    static let logger: Self = .product(name: "Logger", package: "swift-logger")
    static let coreBluetoothTetable: Self = .product(name: "CoreBluetoothTestable", package: "core-bluetooth-testable")
    static let bleAssignedNumbers: Self = .product(name: "BLEAssignedNumbers", package: "swift-ble-assigned-numbers")
    static let bleMacro: Self = .product(name: "BLEMacro", package: "swift-ble-macro")
    static let bleCommand: Self = .product(name: "BLECommand", package: "swift-ble-macro")
    static let bleMacroCompiler: Self = .product(name: "BLEMacroCompiler", package: "swift-ble-macro")
    static let bleInterpreter: Self = .product(name: "BLEInterpreter", package: "swift-ble-macro")
    static let mirrorDiffKit: Self = .product(name: "MirrorDiffKit", package: "MirrorDiffKit")
    static let fuzi: Self = .product(name: "Fuzi", package: "Fuzi")
}
