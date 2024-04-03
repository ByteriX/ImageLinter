//
//  plugin.swift
//
//
//  Created by Sergey Balalaev on 02.04.2024.
//

import PackagePlugin

@main
struct LocalinterPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: Target) throws -> [PackagePlugin.Command] {
        let executable = try context.tool(named: "ImagelinterExec").path

        return [
            .buildCommand(
                displayName: "Running Imagelinter",
                executable: executable,
                arguments: [
//                    "--sourcePath", target.directory.string,
//                    "--imagesPath", target.directory.string,
                ]
            ),
        ]
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension LocalinterPlugin: XcodeBuildToolPlugin {
        func createBuildCommands(context: XcodeProjectPlugin.XcodePluginContext, target: XcodeProjectPlugin.XcodeTarget) throws -> [PackagePlugin.Command] {
            let executable = try context.tool(named: "ImagelinterExec").path

            return [
                .buildCommand(
                    displayName: "Running Imagelinter",
                    executable: executable,
                    arguments: [
//                        "--sourcePath", context.xcodeProject.directory.string,
//                        "--imagesPath", context.xcodeProject.directory.string,
                    ]
                ),
            ]
        }
    }
#endif
