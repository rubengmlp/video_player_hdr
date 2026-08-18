// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "video_player_hdr",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    .library(name: "video-player-hdr", targets: ["video_player_hdr"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "video_player_hdr",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)
