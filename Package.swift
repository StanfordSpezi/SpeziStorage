// swift-tools-version:5.7

//
// This source file is part of the CardinalKit open-source project
// 
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "CardinalKitStorage",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "CardinalKitLocalStorage", targets: ["CardinalKitLocalStorage"]),
        .library(name: "CardinalKitSecureStorage", targets: ["CardinalKitSecureStorage"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordBDHG/CardinalKit", .upToNextMinor(from: "0.3.5")),
        .package(url: "https://github.com/StanfordBDHG/XCTRuntimeAssertions", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        .target(
            name: "CardinalKitLocalStorage",
            dependencies: [
                .product(name: "CardinalKit", package: "CardinalKit"),
                .target(name: "CardinalKitSecureStorage")
            ]
        ),
        .testTarget(
            name: "CardinalKitLocalStorageTests",
            dependencies: [
                .target(name: "CardinalKitLocalStorage")
            ]
        ),
        .target(
            name: "CardinalKitSecureStorage",
            dependencies: [
                .product(name: "CardinalKitCardinalKit", package: "CardinalKit"),
                .product(name: "XCTRuntimeAssertions", package: "XCTRuntimeAssertions")
            ]
        ),
    ]
)
