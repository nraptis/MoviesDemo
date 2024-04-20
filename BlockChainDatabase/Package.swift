// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlockChainDatabase",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BlockChainDatabase",
            targets: ["BlockChainDatabase"]),
    ],
    dependencies: [.package(name: "BlockChainNetworking", path: "BlockChainNetworking")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BlockChainDatabase", dependencies: ["BlockChainNetworking"]),
        .testTarget(
            name: "BlockChainDatabaseTests",
            dependencies: ["BlockChainDatabase", "BlockChainNetworking"]),
    ]
)
