// swift-tools-version: 5.9.0
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
        let path = URL(fileURLWithPath: String(decoding: output, as: UTF8.self))
        return path.deletingLastPathComponent().deletingLastPathComponent().path + "/include/"
    } catch {
        return "/usr/lib/swift"
    }
}

let package = Package(
    name: "swift-ex",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftWithCXX",
            targets: [
                "SwiftWithCXX"
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
            name: "swift-exClient",
            targets: ["swift-exClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio.git", branch: "main"),
        .package(url: "https://github.com/swift-server/async-http-client.git", branch: "main"),
        .package(url: "https://github.com/Genaro-Chris/SignalHandler", branch: "main"),
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "main"),
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
            path: "Implementation"
        ),

        .target(name: "Interface", dependencies: ["Implementation"], path: "Interface"),

        .target(
            name: "CustomExecutor",
            dependencies: [
                "DistributedHTTPActorSystem",
                "CXX_Thread",
            ], path: "CustomExecutor",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableUpcomingFeature("StrictConcurrency=complete"),
            ]),

        // Library that exposes a macro as part of its API, which is used in client programs.

        .executableTarget(
            name: "server",
            dependencies: [
                "DistributedHTTPActorSystem",
                .product(name: "SignalHandler", package: "SignalHandler"),
                "CustomExecutor",
            ],
            path: "server",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableUpcomingFeature("StrictConcurrency=complete"),
            ]),

        .executableTarget(
            name: "client",
            dependencies: [
                "DistributedHTTPActorSystem",
                "CustomExecutor",
                .product(name: "SignalHandler", package: "SignalHandler"),
            ],
            path: "client",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableUpcomingFeature("StrictConcurrency=complete"),
            ]
        ),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(
            name: "swift-exClient",
            dependencies: [
                "SwiftWithCXX",
                "CXX_Thread",
                "SwiftLib",
                "cxxLibrary",
                "CustomExecutor",
                "Interface",
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableExperimentalFeature("GenerateBindingsForThrowingFunctionsInCXX"),
                .enableExperimentalFeature("TypedThrows"),
                .enableUpcomingFeature("FullyTypedThrows"),
                .enableExperimentalFeature("NoImplicitCopy"),
                .enableExperimentalFeature("MoveOnlyClasses"),
                .enableExperimentalFeature("ThenStatements"),
                //.enableExperimentalFeature("NoncopyableGenerics"),
                .enableExperimentalFeature("TypedThrows"),
            ]
        ),

        .target(
            name: "DistributedHTTPActorSystem",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "_NIOConcurrency", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ], path: "DistributedHTTPActorSystem"
        ),

        .target(
            name: "SwiftLib", dependencies: ["SwiftWithCXX", "CXX_Thread"], path: "Swift",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .unsafeFlags([
                    "-module-name", "SwiftLib",
                    "-emit-clang-header-path", "./CXX/include/SwiftLib-Swift.h",
                ]),
            ]
        ),

        .target(
            name: "cxxLibrary", path: "cxxLibrary",
            exclude: [
                "cxxLibraryImpl.cpp", "include/", /* "cxxLibrary.h", */ "omegaException.cpp",
            ],
            publicHeadersPath: "headers/",
            cxxSettings: [
                .unsafeFlags([
                    "-I", tryGuessSwiftLibRoot(),
                ])
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-experimental-move-only"
                ])
            ]),

        .target(
            name: "SwiftWithCXX",
            dependencies: [], path: "CXX",
            cxxSettings: [
                .define("SwiftWithCXX")
            ],
            swiftSettings: [
                .unsafeFlags(
                    [
                        "-Ounchecked"
                    ], .when(platforms: [.windows, .linux]))
            ]),

        .target(
            name: "CXX_Thread",
            dependencies: [], path: "CXX_Thread"),

        // A test target used to develop the macro implementation.
    ],
    cxxLanguageStandard: .cxx2b
)
