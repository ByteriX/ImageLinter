#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

/**
 ImageLinter.swift
 version 1.1

 Created by Sergey Balalaev on 23.09.22.
 Copyright (c) 2022 ByteriX. All rights reserved.

 Script can:
 1. Checking size of PDF and PNG files
 2. Catch raster from PDF
 3. Checking duplicate images
 4. Checking unused image files

 Using from build phase:
 ${SRCROOT}/Scripts/ImageLinter.swift
 */

/// For enable or disable this script
let isEnabled = true

/// Path to folder with images files. For example "/YouProject/Resources/Images"
let relativeImagesPath = "/."

/// Path of the source folder which will used in searching for localization keys you actually use in your project. For Example "/YouProject/Source"
let relativeSourcePath = "/."

/// Using localizations type from code. If you use custom you need define regex pattern
enum UsingType {
    case swiftUI
    case uiKit
    case swiftGen(enumName: String = "Asset")
    case custom(pattern: String)
}

/// yuo can use many types
let usingTypes: [UsingType] = [
    .swiftUI, .uiKit
]

/**
 If you want to exclude unused image from checking, you can define they this

 Example:
  let ignoredUnusedImages = [
     "ApplicationPoster"
  ]
 */
let ignoredUnusedImages: Set<String> = [
]

// Maximum size of PDF files
let maxPdfSize: UInt64 = 10_000

// Maximum size of PNG files
let maxPngSize: UInt64 = 100_000

let isCheckingSize = true
let isCheckingPdfVector = true

// MARK: end of settings the script

let startDate = Date()

var searchUsingRegexPatterns: [String] = []
for usingType in usingTypes {
    switch usingType {
    case .custom(let pattern):
        searchUsingRegexPatterns.append(pattern)
    case .swiftUI:
        searchUsingRegexPatterns.append("Image.*\\(.*\"(\\w+)\"")
    case .uiKit:
        searchUsingRegexPatterns.append("UImage.*\\(.*\named:*\"(\\w+)\"")
    case .swiftGen(let enumName):
        searchUsingRegexPatterns.append(enumName + #"\.((?:\.*[A-Z]{1}[A-z]*[0-9]*)*)\s*((?:\.*[a-z]{1}[A-z]*[0-9]*))\.image"#)
    }
}



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

let imagesetExtension = ".imageset"
let appIconExtension = ".appiconset"
let assetExtension = ".xcassets"
let imageScaleSuffixes = (1...3).map { "@\($0)x" }
class ImageInfo {
    let name: String
    var paths: [String]
    
    init(name: String, path: String) {
        self.name = name
        self.paths = [path]
    }
    
    static func processFound(path: String) {
        var isAsset = false
        let components = path.split(separator: "/")
        for component in components {
            if component.hasSuffix(assetExtension) {
                isAsset = true
            } else {
                if isAsset == false { // only for asset
                    continue
                }
                if component.hasSuffix(imagesetExtension) { // it is asset
                    let name = (component as NSString).substring(to: component.count - imagesetExtension.count)
                    processFound(name: name, path: path)
                    
                    break
                } else if component.hasSuffix(appIconExtension) { // it is Application icon and we will ignore it
                    return
                }
            }
        }
        if !isAsset {
            let name = nameOfImageFile(path: path)
            processFound(name: name, path: path)
        }
    }
    
    static private func processFound(name: String, path: String) {
        if let existImage = foundedImages[name] {
            existImage.paths.append(path)
        } else {
            foundedImages[name] = ImageInfo(name: name, path: path)
        }
    }
    
    static func nameOfImageFile(path: String) -> String {
        return pathOfImageFile(path: (path as NSString).lastPathComponent)
    }
    
    static func pathOfImageFile(path: String) -> String {
        var name = (path as NSString).deletingPathExtension
        for scaleSuffix in imageScaleSuffixes {
            if name.hasSuffix(scaleSuffix) {
                name = String(name.dropLast(scaleSuffix.count))
                break
            }
        }
        return name
    }
    
    static func isTheSameImage(path1: String, path2: String) -> Bool {
        pathOfImageFile(path: path1) == pathOfImageFile(path: path2)
    }
    
    var assetPath: String? {
        var result: String? = nil
        for imageFileName  in paths {
            let components = imageFileName.split(separator: "/")
            if components.count == 0 { // it just image
                return nil
            } else {
                for component in components {
                    if component.hasSuffix(imagesetExtension) { // it is asset
                        var name = (imageFileName as NSString).components(separatedBy: imagesetExtension).first ?? ""
                        name = name + imagesetExtension
                        if let result = result {
                            if name != result {
                                return nil
                            }
                        } else {
                            result = name
                        }
                    }
                }
            }
        }
        return result
    }
    
    func error(with message: String){
        for path in self.paths {
            let imageFilePath = "\(imagesPath)/\(path)"
            printError(filePath: imageFilePath, message: message)
        }
    }
    
    func checkDuplicate() {
        guard paths.count > 1 else {
            return
        }
        if assetPath == nil {
            var isDifferentImages = false
            for path in paths {
                if !Self.isTheSameImage(path1: paths.first ?? "", path2: path) {
                    isDifferentImages = true
                    break
                }
            }
            if isDifferentImages {
                error(with: "Duplicated image with name: '\(name)'")
            }
        }
    }
}

let imageFileEnumerator = FileManager.default.enumerator(atPath: imagesPath)
let pdfRasterPattern = #".*\/[Ii]mage.*"#
let pdfRasterRegex = try? NSRegularExpression(pattern: pdfRasterPattern, options: [])
var foundedImages: [String: ImageInfo] = [:]

while let imageFileName = imageFileEnumerator?.nextObject() as? String {
    if imageFileName.hasSuffix(".pdf") || imageFileName.hasSuffix(".png") {
        
        let imageFilePath = "\(imagesPath)/\(imageFileName)"
        
        ImageInfo.processFound(path: imageFileName)

        let fileSize = fileSize(fromPath: imageFilePath)

        if imageFileName.hasSuffix(".pdf") {
            if isCheckingSize, fileSize > maxPdfSize {
                printError(
                    filePath: imageFilePath,
                    message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: maxPdfSize))."
                )
            }

            if isCheckingPdfVector {
                if let string = try? String(contentsOfFile: imageFilePath, encoding: .ascii) {
                    let range = NSRange(location: 0, length: string.count)
                    if pdfRasterRegex?.firstMatch(in: string, options: [], range: range) != nil {
                        printError(filePath: imageFilePath, message: "PDF File is not vector")
                    }
                } else {
                    printError(filePath: imageFilePath, message: "Can not parse PDF File")
                }
            }
            
        } else if imageFileName.hasSuffix(".png") {
            if isCheckingSize, fileSize > maxPngSize {
                printError(
                    filePath: imageFilePath,
                    message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: maxPngSize))."
                )
            }
        }
    }
}

// MARK: - detect unused Images

let sourcePath = FileManager.default.currentDirectoryPath + relativeSourcePath
let swiftFileEnumerator = FileManager.default.enumerator(atPath: sourcePath)
var usedImages: [String] = []
for regexPattern in searchUsingRegexPatterns {
    let regex = try? NSRegularExpression(pattern: regexPattern, options: [])
    while let sourceFileName = swiftFileEnumerator?.nextObject() as? String {
        // checks the extension
        if sourceFileName.hasSuffix(".swift") || sourceFileName.hasSuffix(".m") || sourceFileName.hasSuffix(".mm") {
            let sourceFilePath = "\(sourcePath)/\(sourceFileName)"
            if let string = try? String(contentsOfFile: sourceFilePath, encoding: .utf8) {
                let range = NSRange(location: 0, length: (string as NSString).length)
                regex?.enumerateMatches(in: string,
                                        options: [],
                                        range: range) { result, _, _ in
                    addUsedImage(from: string, result: result)
                }
            }
        }
    }
}
func addUsedImage(from string: String, result: NSTextCheckingResult?) {
    guard let result = result else {
        return
    }
    // first range is matching, all next is groups
    let value = (1...result.numberOfRanges - 1).map { index in
        (string as NSString).substring(with: result.range(at: index))
    }.joined()
    usedImages.append(value)
}

let unusedImages = Set(foundedImages.keys).subtracting(usedImages).subtracting(ignoredUnusedImages)

for unusedImage in unusedImages {
    if let imageInfo = foundedImages[unusedImage] {
        imageInfo.error(with: "File unused from code.")
    }
}
for imageInfo in foundedImages.values {
    imageInfo.checkDuplicate()
}

print("Number of warnings: \(warningsCount)")
print("Number of errors: \(errorsCount)")
print("Time: \(Date().timeIntervalSince(startDate)) sec.")

if errorsCount > 0 {
    exit(1)
}
