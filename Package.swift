// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "PackStream",
	products: [
	        .library(name: "PackStream", targets: ["PackStream"]),
	    ],
	targets: [
	        .target(
	            name: "PackStream",
	            dependencies: []),
	        .testTarget(
	            name: "PackStreamTests",
	            dependencies: ["PackStream"]),
	    ]
)
