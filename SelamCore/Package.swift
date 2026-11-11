// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SelamCore",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "SelamCore", targets: ["SelamCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/batoulapps/adhan-swift", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "SelamCore",
            dependencies: [.product(name: "Adhan", package: "adhan-swift")]
        ),
        .testTarget(name: "SelamCoreTests", dependencies: ["SelamCore"])
    ]
)
