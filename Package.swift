// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RunimalApple",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "RunimalCore", targets: ["RunimalCore"]),
        .library(name: "RunimalDomainV2", targets: ["RunimalDomainV2"]),
        .library(name: "RunimalSyncV2", targets: ["RunimalSyncV2"]),
        .library(name: "RunimalRewardV2", targets: ["RunimalRewardV2"]),
        .library(name: "RunimalExportV2", targets: ["RunimalExportV2"]),
        .library(name: "RunimalWatchAdapterV2", targets: ["RunimalWatchAdapterV2"]),
        .library(name: "RunimalPhoneAdapterV2", targets: ["RunimalPhoneAdapterV2"]),
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
        .target(
            name: "RunimalDomainV2",
            exclude: ["README.md"]
        ),
        .target(
            name: "RunimalSyncV2",
            dependencies: ["RunimalDomainV2"],
            exclude: ["README.md"]
        ),
        .target(
            name: "RunimalRewardV2",
            dependencies: ["RunimalDomainV2"],
            exclude: ["README.md"]
        ),
        .target(
            name: "RunimalExportV2",
            dependencies: ["RunimalDomainV2"],
            exclude: ["README.md"]
        ),
        .target(
            name: "RunimalWatchAdapterV2",
            dependencies: [
                "RunimalCore",
                "RunimalDomainV2",
                "RunimalSyncV2",
            ],
            exclude: ["README.md"]
        ),
        .target(
            name: "RunimalPhoneAdapterV2",
            dependencies: [
                "RunimalCore",
                "RunimalDomainV2",
            ],
            exclude: ["README.md"]
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
        .testTarget(
            name: "RunimalV2Tests",
            dependencies: [
                "RunimalDomainV2",
                "RunimalSyncV2",
                "RunimalRewardV2",
                "RunimalExportV2",
                "RunimalWatchAdapterV2",
                "RunimalPhoneAdapterV2",
            ],
            exclude: ["README.md"]
        ),
    ]
)
