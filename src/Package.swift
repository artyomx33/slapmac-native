// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SlapMac",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SlapMac", targets: ["SlapMac"])
    ],
    targets: [
        .executableTarget(
            name: "SlapMac",
            path: "SlapMac",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
