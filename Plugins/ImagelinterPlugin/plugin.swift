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
                    "--settingsPath", target.directory.string
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
                        "--settingsPath", context.xcodeProject.directory.string
                    ]
                ),
            ]
        }
    }
#endif
