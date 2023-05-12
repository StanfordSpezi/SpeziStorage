// swift-tools-version:5.7

//
// This source file is part of the Stanford Spezi open-source project
// 
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "SpeziStorage",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "SpeziLocalStorage", targets: ["SpeziLocalStorage"]),
        .library(name: "SpeziSecureStorage", targets: ["SpeziSecureStorage"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordSpezi/Spezi", .upToNextMinor(from: "0.4.1")),
        .package(url: "https://github.com/StanfordSpezi/XCTRuntimeAssertions", .upToNextMinor(from: "0.2.1"))
    ],
    targets: [
        .target(
            name: "SpeziLocalStorage",
            dependencies: [
                .product(name: "Spezi", package: "Spezi"),
                .target(name: "SpeziSecureStorage")
            ]
        ),
        .testTarget(
            name: "SpeziLocalStorageTests",
            dependencies: [
                .target(name: "SpeziLocalStorage")
            ]
        ),
        .target(
            name: "SpeziSecureStorage",
            dependencies: [
                .product(name: "Spezi", package: "Spezi"),
                .product(name: "XCTRuntimeAssertions", package: "XCTRuntimeAssertions")
            ]
        )
    ]
)
