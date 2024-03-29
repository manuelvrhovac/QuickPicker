// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "QuickPicker",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "QuickPicker",
            targets: ["QuickPicker"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/manuelvrhovac/KVFetcher", .upToNextMajor(from: "0.9.1")),
        .package(url: "https://github.com/ReactiveX/RxSwift", .upToNextMajor(from: "5.0.1")),
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "QuickPicker",
            dependencies: ["KVFetcher", "RxSwift", "RxCocoa"],
            path: "Sources"
        )
    ]
)
