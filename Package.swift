// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Navigation",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Navigation",
            targets: ["NavigationDSL"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-perception.git", from: "2.0.0"),
        .package(url: "https://github.com/ekazaev/route-composer.git", from: "2.21.0"),
				.package(url: "https://github.com/pointfreeco/swift-navigation.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "NavigationDSL",
            dependencies: [.product(name: "Perception", package: "swift-perception")]
        ),
        .target(
            name: "SimpleNavigation",
            dependencies: [
                .product(name: "Perception", package: "swift-perception"),
                .product(name: "RouteComposer", package: "route-composer")
            ]
        ),
        .target(
            name: "AsyncNavigation",
            dependencies: [.product(name: "Perception", package: "swift-perception")]
        ),
				.target(
				name: "TCANavigation",
				dependencies: [
					.product(name: "Perception", package: "swift-perception"),
					.product(name: "SwiftNavigation", package: "swift-navigation"),
					.product(name: "UIKitNavigation", package: "swift-navigation")
				]
		),
    ]
)
