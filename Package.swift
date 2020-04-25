// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "MobiledocKit",
    platforms: [
        .macOS(.v10_15), .iOS(.v12)
    ],
    products: [
        .library(
            name: "MobiledockKit",
            targets: ["MobiledocKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MobiledocKit",
            dependencies: [],
            path: "MobiledocKit"
        ),
        .testTarget(
            name: "MobiledockKitTests",
            dependencies: ["MobiledocKit"],
            path: "MobiledocKitTests"
        )
    ]
)
