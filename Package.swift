// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "Agentation",
	platforms: [
		.iOS(.v26)
	],
	products: [
		.library(
			name: "Agentation",
			targets: ["Agentation"]
		)
	],
	targets: [
		.target(
			name: "Agentation",
			path: "Sources/Agentation"
		)
	]
)
