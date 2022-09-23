#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

/// For enable or disable this script
let isEnabled = true

/// Path to folder with images files. For example "/YouProject/Resources/Images"
let relativeImagesPath = ""

// Maximum size of PDF files
let maxPdfSize: UInt64 = 10_000

// Maximum size of PNG files
let maxPngSize: UInt64 = 1000_000

// MARK: end of settings the script

let startDate = Date()

// MARK: detection resources of images

var warningsCount = 0
var errorsCount = 0

// MARK: start analyze

if isEnabled == false {
    let firstArgument = CommandLine.arguments[0]
    print("\(firstArgument):\(#line): warning: localization check cancelled")
    exit(000)
}

func printError(filePath: String, message: String,
                line: Int? = nil, isWarning: Bool = false) {
    var result = filePath
    if let line = line {
        result += ":\(line): "
    } else {
        result += ": "
    }
    result += isWarning ? "warning: " : "error: "
    print(result + message)
    if isWarning {
        warningsCount += 1
    } else {
        errorsCount += 1
    }
}

let imagesPath = FileManager.default.currentDirectoryPath + relativeImagesPath

func fileSize(fromPath path: String) -> UInt64 {
    let size: Any? = try? FileManager.default.attributesOfItem(atPath: path)[FileAttributeKey.size]
    guard let fileSize = size as? UInt64 else {
        printError(filePath: path, message: "Not read file size")
        return 0
    }
    return fileSize
}

func covertToString(fileSize: UInt64) -> String {
    ByteCountFormatter().string(fromByteCount: Int64(fileSize))
}

let imageFileEnumerator = FileManager.default.enumerator(atPath: imagesPath)
while let imageFileName = imageFileEnumerator?.nextObject() as? String {
    if imageFileName.hasSuffix(".pdf") || imageFileName.hasSuffix(".png") {
        let imageFilePath = "\(imagesPath)/\(imageFileName)"

        let fileSize = fileSize(fromPath: imageFilePath)
        
        if imageFileName.hasSuffix(".pdf") {
            if fileSize > maxPdfSize {
                printError(filePath: imageFilePath, message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: maxPdfSize)).")
            }
        } else if imageFileName.hasSuffix(".png") {
            if fileSize > maxPngSize {
                printError(filePath: imageFilePath, message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: maxPngSize)).")
            }
        }
        
    }
}

print("Number of warnings: \(warningsCount)")
print("Number of errors: \(errorsCount)")
print("Time: \(Date().timeIntervalSince(startDate)) sec.")

if errorsCount > 0 {
    exit(1)
}
