// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RunimalApple",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "RunimalCore", targets: ["RunimalCore"]),
        .executable(name: "RunimalCLI", targets: ["RunimalCLI"]),
        .executable(name: "RunimalSelfCheck", targets: ["RunimalSelfCheck"]),
        .executable(name: "RunimalRewardSimulation", targets: ["RunimalRewardSimulation"]),
    ],
    targets: [
        .target(
            name: "RunimalCore",
            resources: [
                .process("Resources"),
            ]
        ),
        .executableTarget(
            name: "RunimalCLI",
            dependencies: ["RunimalCore"]
        ),
        .executableTarget(
            name: "RunimalSelfCheck",
            dependencies: ["RunimalCore"]
        ),
        .executableTarget(
            name: "RunimalRewardSimulation",
            dependencies: ["RunimalCore"]
        ),
        .testTarget(
            name: "RunimalCoreTests",
            dependencies: ["RunimalCore"]
        ),
    ]
)
