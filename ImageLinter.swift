#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

/**
 ImageLinter.swift
 version 1.0

 Created by Sergey Balalaev on 23.09.22.
 Copyright (c) 2022 ByteriX. All rights reserved.

 Script can:
 1. Checking size of PDF and PNG files
 2. Catch raster from PDF 

 Using from build phase:
 ${SRCROOT}/Scripts/ImageLinter.swift
 */

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
    print("\(firstArgument):\(#line): warning: images checking cancelled")
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
let pdfRasterPattern = #".*\/[Ii]mage.*"#
let pdfRasterRegex = try? NSRegularExpression(pattern: pdfRasterPattern, options: [])
while let imageFileName = imageFileEnumerator?.nextObject() as? String {
    if imageFileName.hasSuffix(".pdf") || imageFileName.hasSuffix(".png") {
        let imageFilePath = "\(imagesPath)/\(imageFileName)"

        let fileSize = fileSize(fromPath: imageFilePath)

        if imageFileName.hasSuffix(".pdf") {
            if fileSize > maxPdfSize {
                printError(
                    filePath: imageFilePath,
                    message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: maxPdfSize))."
                )
            }

            if let string = try? String(contentsOfFile: imageFilePath, encoding: .ascii) {
                let range = NSRange(location: 0, length: string.count)
                if pdfRasterRegex?.firstMatch(in: string, options: [], range: range) != nil {
                    printError(filePath: imageFilePath, message: "PDF File is not vector")
                }
            } else {
                printError(filePath: imageFilePath, message: "Can not parse PDF File")
            }

        } else if imageFileName.hasSuffix(".png") {
            if fileSize > maxPngSize {
                printError(
                    filePath: imageFilePath,
                    message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: maxPngSize))."
                )
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
