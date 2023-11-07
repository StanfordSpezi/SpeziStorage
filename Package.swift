// swift-tools-version:5.9

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
        .iOS(.v17)
    ],
    products: [
        .library(name: "SpeziLocalStorage", targets: ["SpeziLocalStorage"]),
        .library(name: "SpeziSecureStorage", targets: ["SpeziSecureStorage"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordSpezi/Spezi", branch: "feature/optimize-observable"),
        .package(url: "https://github.com/StanfordBDHG/XCTRuntimeAssertions", .upToNextMinor(from: "0.2.5"))
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
