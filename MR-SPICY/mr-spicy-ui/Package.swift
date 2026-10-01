// swift-tools-version: 5.9
//
//  MR. SPICY UI — reusable iOS design-system package
//  Version 1.0.0
//
//  NOTE: this package targets iOS (UIKit). It cannot be compiled on Linux;
//  `swift build` must be run on macOS with an iOS toolchain, or the package
//  must be added to an Xcode project. See Documentation/BUILDING.md.
//

import PackageDescription

let package = Package(
    name: "MrSpicyUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "MrSpicyUI", targets: ["MrSpicyUI"])
    ],
    targets: [
        .target(
            name: "MrSpicyUI",
            path: "Sources/MrSpicyUI",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "MrSpicyUITests",
            dependencies: ["MrSpicyUI"],
            path: "Tests/MrSpicyUITests"
        )
    ]
)
