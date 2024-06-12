// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import Foundation
import PackageDescription

func tryGuessSwiftLibRoot() -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", "which swift"]
    task.standardOutput = Pipe()
    do {
        try task.run()
        guard
            let output = (task.standardOutput as? Pipe)?.fileHandleForReading.readDataToEndOfFile()
        else {
            return "/usr/lib/swift"
        }
        return URL(fileURLWithPath: String(decoding: output, as: UTF8.self))
            .deletingLastPathComponent().deletingLastPathComponent().path + "/include/"
    } catch {
        return "/usr/lib/swift"
    }
}

let package = Package(
    name: "swift-ex",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftWithCXX",
            targets: [
                "SwiftWithCXX"
            ]),
        .library(
            name: "shared",
            targets: [
                "shared"
            ]),
        .library(
            name: "Hook",
            targets: [
                "Hook"
            ]),
        .library(
            name: "CXX_Thread",
            targets: [
                "CXX_Thread"
            ]),
        .library(
            name: "SwiftLib",
            targets: [
                "SwiftLib"
            ]),
        .library(
            name: "CustomExecutor",
            targets: [
                "CustomExecutor"
            ]
        ),
        .library(
            name: "DistributedHTTPActorSystem",
            targets: [
                "DistributedHTTPActorSystem"
            ]),
        .library(
            name: "cxxLibrary",
            targets: [
                "cxxLibrary"
            ]),
        .library(
            name: "swiftImpl",
            targets: [
                "swiftImpl"
            ]),
        .library(
            name: "ThreadPool",
            targets: [
                "ThreadPool"
            ]),
        .executable(
            name: "server",
            targets: [
                "server"
            ]
        ),
        .executable(
            name: "client",
            targets: [
                "client"
            ]
        ),
        .executable(
            name: "swift-ex",
            targets: ["swift-ex"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio.git", branch: "main"),
        .package(url: "https://github.com/swift-server/async-http-client.git", branch: "main"),
        .package(url: "https://github.com/Genaro-Chris/SignalHandler", branch: "main"),
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-testing.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "Implementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ],
            path: "Implementation",
            swiftSettings: [
                .enableExperimentalFeature("BodyMacros"),
                .enableExperimentalFeature("CodeItemMacros"),
                .enableExperimentalFeature("PreambleMacros"),
            ]
        ),

        .target(
            name: "shared",
            dependencies: [
                "DistributedHTTPActorSystem"
            ], path: "shared",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend",
                    "-validate-tbd-against-ir=none",
                    "-Xfrontend",
                    "-enable-library-evolution",
                ]),
                //.enableExperimentalFeature("AccessLevelOnImport"),
                //.enableUpcomingFeature("InternalImportsByDefault")
            ]),

        .target(
            name: "Interface", dependencies: ["Implementation"], path: "Interface",
            swiftSettings: [
                .enableExperimentalFeature("BodyMacros"),
                .enableExperimentalFeature("CodeItemMacros"),
                .enableExperimentalFeature("PreambleMacros"),
            ]),

        .target(
            name: "CustomExecutor",
            dependencies: [
                "CXX_Thread",
                "ThreadPool",
            ], path: "CustomExecutor",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .unsafeFlags(
                    [
                        "-I", tryGuessSwiftLibRoot(),
                    ]),
            ]),

        // Library that exposes a macro as part of its API, which is used in client programs.

        .executableTarget(
            name: "server",
            dependencies: [
                .product(name: "SignalHandler", package: "SignalHandler"),
                "shared",
            ],
            path: "server",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableUpcomingFeature("StrictConcurrency=complete"),
                .enableExperimentalFeature("IsolatedAny"),
                .unsafeFlags([
                    "-I", tryGuessSwiftLibRoot(),
                ]),
            ]),

        .executableTarget(
            name: "client",
            dependencies: [
                "shared",
                .product(name: "SignalHandler", package: "SignalHandler"),
            ],
            path: "client",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableUpcomingFeature("StrictConcurrency=complete"),
                .unsafeFlags([
                    "-I", tryGuessSwiftLibRoot(),
                ]),
            ]
        ),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(
            name: "swift-ex",
            dependencies: [
                "SwiftWithCXX",
                "CXX_Thread",
                "SwiftLib",
                "cxxLibrary",
                "CustomExecutor",
                "Interface",
                "Hook",
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableExperimentalFeature("GenerateBindingsForThrowingFunctionsInCXX"),
                .enableExperimentalFeature("TypedThrows"),
                .enableUpcomingFeature("FullyTypedThrows"),
                .enableExperimentalFeature("NoImplicitCopy"),
                .enableExperimentalFeature("ExtractConstantsFromMembers"),
                .enableExperimentalFeature("SymbolLinkageMarkers"),
                .enableExperimentalFeature("MoveOnlyClasses"),
                .enableExperimentalFeature("ThenStatements"),
                .enableExperimentalFeature("BuiltinModule"),
                .enableExperimentalFeature("BodyMacros"), // default swift 6 release
                .enableExperimentalFeature("PreambleMacros"),
                .enableExperimentalFeature("CodeItemMacros"),
                .enableExperimentalFeature("ImplicitLastExprResults"),
                .enableExperimentalFeature("PackIteration"),
                .enableExperimentalFeature("NoncopyableGenerics"),
                .enableExperimentalFeature("StaticExclusiveOnly"),
                .enableExperimentalFeature("Sensitive"),
                .enableExperimentalFeature("TransferringArgsAndResults"),
                .enableExperimentalFeature("NonescapableTypes"),
                .enableUpcomingFeature("ImplicitOpenExistenials"),
                .enableExperimentalFeature("OpaqueTypeErasure"),
                .enableExperimentalFeature("IsolatedAny"),
                .enableExperimentalFeature("IsolatedAny2"),
                .enableExperimentalFeature("BuiltinModule"),
                .enableExperimentalFeature("BorrowingSwitch"),
                .enableExperimentalFeature("DynamicActorIsolation"),
                .enableExperimentalFeature("MoveOnlyPartialConsumption"),
                .enableExperimentalFeature("OptionalIsolatedParameters"),
                .enableExperimentalFeature("ClosureIsolation"),
                .enableExperimentalFeature("GlobalActorIsolatedTypesUsability"),
                //.enableExperimentalFeature("AccessLevelOnImport"),
                //.enableUpcomingFeature("InternalImportsByDefault")
                .define("SWIFTSETTINGS"),
                .define("TEST_DIAGNOSTICS"),
                .unsafeFlags(
                    [
                        "-DEXAMPLESETTINGS",
                        "-I", tryGuessSwiftLibRoot(),
                        "-Xfrontend", "-disable-availability-checking",
                        // "-continue-building-after-errors",
                        // "-cross-module-optimization",
                         "-wmo",
                        "-Xfrontend", "-disable-round-trip-debug-types",
                    ]),
            ]
        ),

        .target(
            name: "DistributedHTTPActorSystem",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "_NIOConcurrency", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ], path: "DistributedHTTPActorSystem",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-enable-private-imports",
                    //"-enable-library-evolution"
                ])
            ]
        ),

        .target(name: "swiftImpl", dependencies: [], path: "swift_impl"),

        .target(name: "Hook", dependencies: [], path: "hooks", publicHeadersPath: "."),

        .target(name: "ThreadPool", dependencies: [], path: "ThreadPool"),

        .target(
            name: "SwiftLib", dependencies: ["SwiftWithCXX"],
            path: "Swift",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableExperimentalFeature("Extern"),
                .unsafeFlags([
                    "-module-name", "SwiftLib",
                    "-emit-clang-header-path", "./CXX/include/SwiftLib-Swift.h",
                    "-I", tryGuessSwiftLibRoot(),
                ]),
            ]
        ),

        .target(
            name: "cxxLibrary", path: "cxxLibrary",
            exclude: [
                /* "cxxLibraryImpl.cpp", "include/", */ "headers/", "omegaException.cpp"
            ],
            //publicHeadersPath: "headers/",
            cxxSettings: [
                .unsafeFlags([
                    "-I", tryGuessSwiftLibRoot(),
                ])
            ]),

        .target(
            name: "SwiftWithCXX",
            dependencies: [], path: "CXX",
            cxxSettings: [
                .unsafeFlags([
                    "-I", tryGuessSwiftLibRoot(),
                ])
            ]),

        .target(
            name: "CXX_Thread",
            dependencies: [], path: "CXX_Thread", exclude: ["threadpoolimpl.cpp"],
            cxxSettings: [
                .unsafeFlags([
                    "-I", tryGuessSwiftLibRoot(),
                    "-O3"
                ])
            ]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "TestExample",
            dependencies: [
                .product(name: "Testing", package: "swift-testing")
            ], path: "tests",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "--enable-experimental-swift-testing"
                ])
            ]),
    ],
    cxxLanguageStandard: .cxx2b
)
