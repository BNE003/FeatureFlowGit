// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "FeatureFlow",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "FeatureFlow",
            targets: ["FeatureFlow"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FeatureFlow",
            dependencies: [],
            resources: [.process("requirements.md")]),
        .testTarget(
            name: "FeatureFlowTests",
            dependencies: ["FeatureFlow"]),
    ]
)
