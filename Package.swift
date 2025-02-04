// swift-tools-version:6.0

//
// This source file is part of the Stanford Spezi open-source project
// 
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import class Foundation.ProcessInfo
import PackageDescription


let package = Package(
    name: "SpeziStorage",
    platforms: [
        .iOS(.v17),
        .visionOS(.v1),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SpeziLocalStorage", targets: ["SpeziLocalStorage"]),
        .library(name: "SpeziCredentialsStorage", targets: ["SpeziCredentialsStorage"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordSpezi/Spezi", from: "1.7.3"),
        .package(url: "https://github.com/StanfordSpezi/SpeziFoundation", from: "2.0.0"),
        .package(url: "https://github.com/StanfordBDHG/XCTRuntimeAssertions", from: "1.1.1")
    ] + swiftLintPackage(),
    targets: [
        .target(
            name: "SpeziLocalStorage",
            dependencies: [
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "SpeziFoundation", package: "SpeziFoundation"),
                .target(name: "SpeziCredentialsStorage")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .testTarget(
            name: "SpeziLocalStorageTests",
            dependencies: [
                .target(name: "SpeziLocalStorage"),
                .product(name: "XCTSpezi", package: "Spezi")
            ],
            plugins: [] + swiftLintPlugin()
        ),
        .target(
            name: "SpeziCredentialsStorage",
            dependencies: [
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "XCTRuntimeAssertions", package: "XCTRuntimeAssertions")
            ],
            plugins: [] + swiftLintPlugin()
        )
    ]
)


func swiftLintPlugin() -> [Target.PluginUsage] {
    // Fully quit Xcode and open again with `open --env SPEZI_DEVELOPMENT_SWIFTLINT /Applications/Xcode.app`
    if ProcessInfo.processInfo.environment["SPEZI_DEVELOPMENT_SWIFTLINT"] != nil {
        [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
    } else {
        []
    }
}

func swiftLintPackage() -> [PackageDescription.Package.Dependency] {
    if ProcessInfo.processInfo.environment["SPEZI_DEVELOPMENT_SWIFTLINT"] != nil {
        [.package(url: "https://github.com/realm/SwiftLint.git", from: "0.55.1")]
    } else {
        []
    }
}
