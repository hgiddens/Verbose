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
      .package(url: "https://github.com/hummingbird-community/hummingbird-elementary.git", from: "0.4.1"),
      .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.4"),
      .package(url: "https://github.com/sliemeobn/elementary.git", from: "0.5.2"),
    ],
    targets: [
      .target(
        name: "Solver",
        dependencies: [],
        path: "Sources/Solver",
      ),
      .testTarget(
        name: "SolverTests",
        dependencies: [.byName(name: "Solver")],
        path: "Tests/SolverTests",
      ),
      .executableTarget(
        name: "Verbose",
        dependencies: [
          .byName(name: "Solver"),
          .product(name: "ArgumentParser", package: "swift-argument-parser"),
          .product(name: "Elementary", package: "elementary"),
          .product(name: "Hummingbird", package: "hummingbird"),
          .product(name: "HummingbirdElementary", package: "hummingbird-elementary"),
        ],
        path: "Sources/App",
        resources: [.process("words.txt")],
      ),
      .testTarget(
        name: "VerboseTests",
        dependencies: [
          .byName(name: "Verbose"),
          .product(name: "HummingbirdTesting", package: "hummingbird"),
        ],
        path: "Tests/AppTests",
      )
    ]
)
