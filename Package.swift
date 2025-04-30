// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TestiOSApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TestiOSApp",
            targets: ["TestiOSApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.17.1")
    ],
    targets: [
        .target(
            name: "TestiOSApp",
            dependencies: ["XMLCoder"]),
        .testTarget(
            name: "TestiOSAppTests",
            dependencies: ["TestiOSApp"]),
    ]
) 