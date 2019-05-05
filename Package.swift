// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "eff",
	products: [
		.library(name: "eff", targets: ["eff"])
	],
    dependencies: [
        .package(url: "https://github.com/edahlseng/utils.git", "0.1.0" ..< "0.2.0"),
    ],
    targets: [
        .target(name: "eff", dependencies: ["utils"], path: "./sources"),
    ],
    swiftLanguageVersions: [.v4_2]
)
