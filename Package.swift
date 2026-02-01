// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EchoRead",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "EchoRead", targets: ["EchoRead"])
    ],
    targets: [
        .executableTarget(
            name: "EchoRead",
            path: ".",
            exclude: [
                "Package.swift",
                "Info.plist",
                "Config.xcconfig",
                "bundle_app.sh",
                "package_ipad.sh",
                "EchoRead.app", 
                "README.md",
                "RUNNING_GUIDE.md",
                "run_on_device_instructions.md",
                "run_on_device_instructions copy.md"
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Info.plist"
                ])
            ]
        )
    ]
)
