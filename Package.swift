// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Verbose",
    platforms: [.macOS(.v15)],
    products: [
      .executable(name: "Verbose", targets: ["Verbose"]),
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.1"),
      .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.4"),
    ],
    targets: [
      .executableTarget(name: "Verbose",
                        dependencies: [
                          .product(name: "ArgumentParser", package: "swift-argument-parser"),
                          .product(name: "Hummingbird", package: "hummingbird"),
                        ],
                        path: "Sources/App",
      ),
      .testTarget(name: "VerboseTests",
                  dependencies: [
                    .byName(name: "Verbose"),
                    .product(name: "HummingbirdTesting", package: "hummingbird"),
                  ],
                  path: "Tests/AppTests",
      )
    ]
)
