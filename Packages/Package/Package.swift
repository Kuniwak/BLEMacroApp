// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Package",
    platforms: [
        .iOS(.v17),
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
        .package(url: "https://github.com/Kuniwak/swift-logger.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Kuniwak/swift-ble-assigned-numbers.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Kuniwak/core-bluetooth-testable.git", .upToNextMajor(from: "5.0.1")),
        .package(url: "https://github.com/Kuniwak/swift-ble-macro.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/cezheng/Fuzi.git", .upToNextMajor(from: "3.1.3")),
        .package(url: "https://github.com/Kuniwak/MirrorDiffKit.git", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/Nirma/SFSymbol.git", .upToNextMajor(from: "2.3.0")),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "ModelFoundation",
            swiftSettings: SwiftSetting.allCases
        ),
        .target(
            name: "Catalogs",
            dependencies: [
                .bleInternal,
                .bleAssignedNumbers,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .testTarget(
            name: "CatalogTests",
            dependencies: [
                .catalogs,
                .bleAssignedNumbers,
                .testing,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .target(
            name: "CoreBluetoothTasks",
            dependencies: [
                .coreBluetoothTestable,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .target(
            name: "ConcurrentCombine",
            dependencies: [
                .taskExtensions,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .testTarget(
            name: "ConcurrentCombineTests",
            dependencies: [
                .concurrentCombine,
                .testing,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .target(
            name: "TaskExtensions",
            swiftSettings: SwiftSetting.allCases
        ),
        .testTarget(
            name: "TaskExtensionTests",
            dependencies: [
                .taskExtensions,
                .testing,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .target(
            name: "Models",
            dependencies: [
                .modelFoundation,
                .logger,
                .fuzi,
                .mirrorDiffKit,
                .concurrentCombine,
                .taskExtensions,
                .coreBluetoothTestable,
                .coreBluetoothTasks,
                .bleAssignedNumbers,
                .bleMacro,
                .bleMacroCompiler,
                .bleCommand,
                .bleInterpreter,
                .bleModel,
                .catalogs,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .target(
            name: "ModelStubs",
            dependencies: [
                .modelFoundation,
                .models,
                .bleModelStub,
                .catalogs,
                .concurrentCombine,
                .coreBluetoothTestable,
                .coreBluetoothStub,
                .mirrorDiffKit,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .testTarget(
            name: "ModelTests",
            dependencies: [
                .modelFoundation,
                .logger,
                .coreBluetoothStub,
                .coreBluetoothTestable,
                .catalogs,
                .models,
                .modelStubs,
                .mirrorDiffKit,
                .testing,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .target(
            name: "Views",
            dependencies: [
                .modelFoundation,
                .viewFoundation,
                .previewHelper,
                .models,
                .modelStubs,
                .coreBluetoothTestable,
                .coreBluetoothStub,
                .sfSymbol,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .target(
            name: "ViewFoundation",
            dependencies: [
                .modelFoundation,
                .concurrentCombine,
            ],
            swiftSettings: SwiftSetting.allCases
        ),
        .target(
            name: "PreviewHelper",
            swiftSettings: SwiftSetting.allCases
        ),
    ]
)

private extension Target.Dependency {
    static let previewHelper: Self = "PreviewHelper"
    static let viewFoundation: Self = "ViewFoundation"
    static let catalogs: Self = "Catalogs"
    static let modelFoundation: Self = "ModelFoundation"
    static let models: Self = "Models"
    static let modelStubs: Self = "ModelStubs"
    static let logger: Self = .product(name: "Logger", package: "swift-logger")
    static let coreBluetoothTestable: Self = .product(name: "CoreBluetoothTestable", package: "core-bluetooth-testable")
    static let coreBluetoothStub: Self = .product(name: "CoreBluetoothStub", package: "core-bluetooth-testable")
    static let coreBluetoothTasks: Self = "CoreBluetoothTasks"
    static let concurrentCombine: Self = "ConcurrentCombine"
    static let taskExtensions: Self = "TaskExtensions"
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
    static let sfSymbol: Self = "SFSymbol"
    static let testing: Self = .product(name: "Testing", package: "swift-testing")
}


extension SwiftSetting {
    /// Forward-scan matching for trailing closures
    /// - Version: Swift 5.3
    /// - Since: SwiftPM 5.8
    /// - SeeAlso: [SE-0286: Forward-scan matching for trailing closures](https://github.com/apple/swift-evolution/blob/main/proposals/0286-forward-scan-trailing-closures.md)
    static let forwardTrailingClosures: Self = .enableUpcomingFeature("ForwardTrailingClosures")
    /// Introduce existential `any`
    /// - Version: Swift 5.6
    /// - Since: SwiftPM 5.8
    /// - SeeAlso: [SE-0335: Introduce existential `any`](https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md)
    static let existentialAny: Self = .enableUpcomingFeature("ExistentialAny")
    /// Regex Literals
    /// - Version: Swift 5.7
    /// - Since: SwiftPM 5.8
    /// - SeeAlso: [SE-0354: Regex Literals](https://github.com/apple/swift-evolution/blob/main/proposals/0354-regex-literals.md)
    static let bareSlashRegexLiterals: Self = .enableUpcomingFeature("BareSlashRegexLiterals")
    /// Concise magic file names
    /// - Version: Swift 5.8
    /// - Since: SwiftPM 5.8
    /// - SeeAlso: [SE-0274: Concise magic file names](https://github.com/apple/swift-evolution/blob/main/proposals/0274-magic-file.md)
    static let conciseMagicFile: Self = .enableUpcomingFeature("ConciseMagicFile")
    /// Importing Forward Declared Objective-C Interfaces and Protocols
    /// - Version: Swift 5.9
    /// - Since: SwiftPM 5.9
    /// - SeeAlso: [SE-0384: Importing Forward Declared Objective-C Interfaces and Protocols](https://github.com/apple/swift-evolution/blob/main/proposals/0384-importing-forward-declared-objc-interfaces-and-protocols.md)
    static let importObjcForwardDeclarations: Self = .enableUpcomingFeature("ImportObjcForwardDeclarations")
    /// Remove Actor Isolation Inference caused by Property Wrappers
    /// - Version: Swift 5.9
    /// - Since: SwiftPM 5.9
    /// - SeeAlso: [SE-0401: Remove Actor Isolation Inference caused by Property Wrappers](https://github.com/apple/swift-evolution/blob/main/proposals/0401-remove-property-wrapper-isolation.md)
    static let disableOutwardActorInference: Self = .enableUpcomingFeature("DisableOutwardActorInference")
    /// Deprecate `@UIApplicationMain` and `@NSApplicationMain`
    /// - Version: Swift 5.10
    /// - Since: SwiftPM 5.10
    /// - SeeAlso: [SE-0383: Deprecate `@UIApplicationMain` and `@NSApplicationMain`](https://github.com/apple/swift-evolution/blob/main/proposals/0383-deprecate-uiapplicationmain-and-nsapplicationmain.md)
    static let deprecateApplicationMain: Self = .enableUpcomingFeature("DeprecateApplicationMain")
    /// Isolated default value expressions
    /// - Version: Swift 5.10
    /// - Since: SwiftPM 5.10
    /// - SeeAlso: [SE-0411: Isolated default value expressions](https://github.com/apple/swift-evolution/blob/main/proposals/0411-isolated-default-values.md)
    static let isolatedDefaultValues: Self = .enableUpcomingFeature("IsolatedDefaultValues")
    /// Strict concurrency for global variables
    /// - Version: Swift 5.10
    /// - Since: SwiftPM 5.10
    /// - SeeAlso: [SE-0412: Strict concurrency for global variables](https://github.com/apple/swift-evolution/blob/main/proposals/0412-strict-concurrency-for-global-variables.md)
    static let globalConcurrency: Self = .enableUpcomingFeature("GlobalConcurrency")
}


extension SwiftSetting {
    public static var allCases: [Self] {
        [
            .forwardTrailingClosures,
            .existentialAny,
            .bareSlashRegexLiterals,
            .conciseMagicFile,
            .importObjcForwardDeclarations,
            .disableOutwardActorInference,
            .deprecateApplicationMain,
            .isolatedDefaultValues,
            .globalConcurrency,
        ]
    }
}
