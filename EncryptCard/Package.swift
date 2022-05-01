// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EncryptCard",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "EncryptCard",
            targets: ["EncryptCard"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.5.1"))
    ],
    targets: [
        .target(
            name: "EncryptCard",
            dependencies: [
                .product(name: "CryptoSwift", package: "CryptoSwift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "EncryptCardTests",
            dependencies: ["EncryptCard"],
            path: "Tests",
            resources: [.copy("example-payment-gateway-key.txt")]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
