//
//  main.swift
//
//
//  Created by Sergey Balalaev on 02.04.2024.
//

import Foundation
import AppKit

// MARK: begin of settings the script

let settings = Settings()

// MARK: end of settings the script

let startDate = Date()

let imageSetExtensions = settings.rastorExtensions.union(settings.vectorExtensions)

var searchUsingRegexPatterns: [String] = []
var isSwiftGen = false
for usingType in settings.usingTypes {
    switch usingType {
    case .custom(let pattern):
        searchUsingRegexPatterns.append(pattern)
    case .swiftUI:
        searchUsingRegexPatterns.append(#"\bImage\(\s*"(.*)"\s*\)"#)
    case .uiKit:
        searchUsingRegexPatterns.append(#"\bUIImage\(\s*named:\s*"(.*)"\s*\)"#)
    case .swiftGen(let enumName):
        searchUsingRegexPatterns
            .append(enumName +
                #"\s*\.((?:\.*[A-Z]{1}[A-z0-9]*)*)\s*((?:\.*[a-z]{1}[A-z0-9]*))(?:\s*\.image|\s*\.uiImage)"#)
        isSwiftGen = true
    }
}

let allImageScales = (1...3)
var targetScales: Set<Int> = []
for targetPlatform in settings.targetPlatforms {
    switch targetPlatform {
    case .iPadOS, .visionOS, .watchOS:
        targetScales.insert(2)
    case .iOS:
        targetScales.insert(2)
        targetScales.insert(3)
    case .macOS, .tvOS:
        targetScales.insert(1)
        targetScales.insert(2)
    }
}
if targetScales.count < 1 {
    print("\(CommandLine.arguments[0]):\(#line): error: targetPlatforms should have one or more values. It need for detect quality of images.")
}

// MARK: detection resources of images



var warningsCount = 0
var errorsCount = 0

// MARK: start analyze

if settings.isEnabled == false {
    print("\(CommandLine.arguments[0]):\(#line): warning: images checking cancelled")
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

extension String {
    var linesCount: Int {
        return reduce(into: 1) { count, letter in
            if letter == "\n" { // This treats CRLF as one "letter", contrary to UnicodeScalars
                count += 1
            }
        }
    }

    var scale: Int? {
        guard (self as NSString).contains("x") else {
            return nil
        }
        return Int(dropLast(1))
    }

    func lowercasedFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
}

extension Array where Self.Element == String {
    func swiftGen() -> [Self.Element] {
        guard let last = last else {
            return self
        }
        var result: [Self.Element] = dropLast()
        result.append(last.lowercasedFirstLetter())
        return result
    }
}

extension NSImage {
    var pixelSize: NSSize? {
        if let rep = representations.first {
            let size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            return size
        }
        return nil
    }
}

extension CGImage {
    var png: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}

let imagesPath = FileManager.default.currentDirectoryPath + settings.relativeImagesPath
print("image folder: \(imagesPath)")

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
let svgRasterPattern = #".*<image .*"#
let svgRasterRegex = try? NSRegularExpression(pattern: svgRasterPattern, options: [])

var foundedImages: [String: ImageInfo] = [:]

while let imageFileName = imageFileEnumerator?.nextObject() as? String {
    let fileExtension = (imageFileName as NSString).pathExtension.uppercased()
    if imageSetExtensions.contains(fileExtension) {
        let imageFilePath = "\(imagesPath)/\(imageFileName)"

        if let imageInfo = ImageInfo.processFound(path: imageFileName){

            let fileSize = fileSize(fromPath: imageFilePath)

            if settings.vectorExtensions.contains(fileExtension) {
                if settings.isCheckingFileSize, fileSize > settings.maxVectorFileSize {
                    printError(
                        filePath: imageFilePath,
                        message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: settings.maxVectorFileSize)). Found for image '\(imageInfo.name)'"
                    )
                }

                if settings.isCheckingPdfVector || settings.isCheckingSvgVector {
                    if let string = try? String(contentsOfFile: imageFilePath, encoding: .ascii) {
                        let range = NSRange(location: 0, length: string.count)
                        if settings.isCheckingPdfVector, pdfRasterRegex?.firstMatch(in: string, options: [], range: range) != nil {
                            printError(filePath: imageFilePath, message: "PDF File is not vector. Found for image '\(imageInfo.name)'")
                        }
                        if settings.isCheckingSvgVector, svgRasterRegex?.firstMatch(in: string, options: [], range: range) != nil {
                            printError(filePath: imageFilePath, message: "SVG File is not vector. Found for image '\(imageInfo.name)'")
                        }
                    } else {
                        printError(filePath: imageFilePath, message: "Can not parse Vector file. Found for image '\(imageInfo.name)'")
                    }
                }
            } else if settings.rastorExtensions.contains(fileExtension) {
                if settings.isCheckingFileSize, fileSize > settings.maxRastorFileSize {
                    printError(
                        filePath: imageFilePath,
                        message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: settings.maxRastorFileSize)). Found for image '\(imageInfo.name)'"
                    )
                }
            }
        }
    } else if imageFileName.hasSuffix(imagesetExtension) {
        let imageFilePath = "\(imagesPath)/\(imageFileName)"
        let fileEnumerator = FileManager.default.enumerator(atPath: imageFilePath)
        var files: Set<String> = []
        while let fileName = fileEnumerator?.nextObject() as? String {
            files.insert(fileName)
        }
        let name = ((imageFileName as NSString).lastPathComponent as NSString).deletingPathExtension
        if let content = load(AssetContents.self, for: imageFileName) {
            let contentFileNames = Set<String>(content.images.compactMap { $0.filename })
            if contentFileNames.isEmpty {
                printError(filePath: imageFileName, message: "Empty asset with name '\(name)'")
            }
            let notFoundFile = contentFileNames.subtracting(files)
            for file in notFoundFile {
                printError(filePath: imageFileName, message: "Not found file '\(file)' for Asset with name '\(name)'")
            }
        } else {
            printError(filePath: imageFileName, message: "Empty folder for Asset with name '\(name)'")
        }
    }
}

// MARK: - detect unused Images

let sourcePath = FileManager.default.currentDirectoryPath + settings.relativeSourcePath
print("source folder: \(sourcePath)")
var usedImages: [String] = []
let sourcesRegex = searchUsingRegexPatterns.compactMap { regexPattern in
    let regex = try? NSRegularExpression(pattern: regexPattern, options: [])
    if regex == nil {
        printError(filePath: #file, message: "Not right pattern for regex: \(regexPattern)", line: #line)
    }
    return regex
}
let resourcesRegex = try! NSRegularExpression(pattern: #"<\bimage name="(.[A-z0-9]*)""#, options: [])
// Search all using
let sourceFileEnumerator = FileManager.default.enumerator(atPath: sourcePath)
while let sourceFileName = sourceFileEnumerator?.nextObject() as? String {
    let fileExtension = (sourceFileName as NSString).pathExtension.uppercased()
    let filePath = "\(sourcePath)/\(sourceFileName)"
    // checks the extension to source
    if settings.sourcesExtensions.contains(fileExtension) {
        if let string = try? String(contentsOfFile: filePath, encoding: .utf8) {
            let range = NSRange(location: 0, length: (string as NSString).length)
            sourcesRegex.forEach{ regex in
                regex.enumerateMatches(in: string,
                                        options: [],
                                        range: range) { result, _, _ in
                    addUsedImage(from: string, result: result, path: filePath)
                }
            }
        }
    } else if settings.resourcesExtensions.contains(fileExtension) { // checks the extension to resource
        if let string = try? String(contentsOfFile: filePath, encoding: .utf8) {
            let range = NSRange(location: 0, length: (string as NSString).length)
            resourcesRegex.enumerateMatches(in: string,
                                    options: [],
                                    range: range) { result, _, _ in
                addUsedImage(from: string, result: result, path: filePath)
            }
        }
    }
}

func addUsedImage(from string: String, result: NSTextCheckingResult?, path: String) {
    guard let result = result, result.numberOfRanges > 0 else {
        return
    }
    // first range is matching, all next is groups
    let value = (1...result.numberOfRanges - 1).map { index in
        (string as NSString).substring(with: result.range(at: index))
    }.joined()
    usedImages.append(value)
    if foundedImages[value] == nil, settings.ignoredUndefinedImages.contains(value) == false {
        let line = (string as NSString).substring(with: NSRange(location: 0, length: result.range(at: 0).location)).linesCount

        printError(filePath: path, message: "Not found image with name '\(value)'", line: line)
    }
}

let unusedImages = Set(foundedImages.keys).subtracting(usedImages).subtracting(settings.ignoredUnusedImages)
for unusedImage in unusedImages {
    if let imageInfo = foundedImages[unusedImage] {
        imageInfo.error(with: "File unused from code. Found for image '\(imageInfo.name)'")
    }
}

let images: [ImageInfo] = foundedImages.values.map { $0 }
for imageInfo in images {
    if settings.isCheckingDuplicatedByName {
        imageInfo.checkDuplicateByName()
    }
    if settings.isCheckingScaleSize {
        imageInfo.checkImageSizeAndDetectType()
    }
    if settings.isCheckingDuplicatedByContent {
        if let data = imageInfo.calculateData() {
            imageInfo.hash = "\(data.count)"
        }
    }
}

if settings.isCheckingDuplicatedByContent {
    for (index, imageInfo1) in images.enumerated() {
        for i in index + 1..<images.count {
            let imageInfo2 = images[i]
            if imageInfo1.hash.isEmpty == false, imageInfo1.hash == imageInfo2.hash,
               imageInfo1.calculateData() == imageInfo2.calculateData() {
                let file1 = imageInfo1.files.first!
                let imageFilePath1 = "\(imagesPath)/\(file1.path)"
                let file2 = imageInfo2.files.first!
                let imageFilePath2 = "\(imagesPath)/\(file2.path)"
                printError(filePath: imageFilePath1, message: "image '\(imageInfo1.name)' duplicate by content '\(imageInfo2.name)' with path '\(imageFilePath2)'")
            }
        }
    }
}

print("Number of images: \(foundedImages.values.reduce(into: 0) { $0 += $1.files.count })")
print("Number of warnings: \(warningsCount)")
print("Number of errors: \(errorsCount)")
print("Time: \(Date().timeIntervalSince(startDate)) sec.")

if errorsCount > 0 {
    exit(1)
}
