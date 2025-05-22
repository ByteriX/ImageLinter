#!/usr/bin/env xcrun --sdk macosx swift

import Foundation
import AppKit

let version = UserDefaults.standard.string(forKey: "version")!

let path = "Sources/ImagelinterExec"
let sourceFileEnumerator = FileManager.default.enumerator(atPath: path)
let startStrings = """
#!/usr/bin/env xcrun --sdk macosx swift

import Foundation
import AppKit

/**
 ImageLinter.swift
 version \(version)

 Created by Sergey Balalaev on 23.09.22.
 Copyright (c) 2022-2025 ByteriX. All rights reserved.

 Using from build phase:
 ${SRCROOT}/Scripts/ImageLinter.swift
 */


"""

var saveString = startStrings

while let sourceFileName = sourceFileEnumerator?.nextObject() as? String {
    let fileExtension = (sourceFileName as NSString).pathExtension.uppercased()
    let filePath = "\(path)/\(sourceFileName)"
    // checks the extension to source
    if fileExtension.contains("SWIFT") {
        if let string = try? String(contentsOfFile: filePath, encoding: .utf8) {
            saveString.append(string)
        }
    }
}

try saveString.data(using: .utf8)?.write(to: URL(fileURLWithPath: "Imagelinter.swift"))
