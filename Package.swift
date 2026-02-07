// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "UICrit",
	platforms: [
		.iOS(.v16)
	],
	products: [
		.library(
			name: "UICrit",
			targets: ["UICrit"]
		)
	],
	targets: [
		.target(
			name: "UICrit",
			path: "Sources/UICrit"
		)
	]
)
