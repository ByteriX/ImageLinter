#!/usr/bin/env xcrun --sdk macosx swift

import Foundation
import AppKit

/**
 ImageLinter.swift
 version 1.2.1

 Created by Sergey Balalaev on 23.09.22.
 Copyright (c) 2022 ByteriX. All rights reserved.

 Script can:
 1. Checking size of PDF and PNG files
 2. Catch raster from PDF
 3. Checking unused image files
 4. Search undefined images
 5. Comparing scaled images size
 6. Checking duplicate images by name
 7. Checking duplicate images by content (but identical)

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
let ignoredUndefinedImages: Set<String> = [
]

let rastorExtensions: Set<String> = ["png", "jpg", "jpeg"]
let vectorExtensions: Set<String> = ["pdf"]
let imageExtensions = rastorExtensions.union(vectorExtensions)

// Maximum size of PDF files
let maxPdfSize: UInt64 = 10_000

// Maximum size of PNG files
let maxPngSize: UInt64 = 100_000

let isCheckingFileSize = true
let isCheckingPdfVector = true
let isCheckingScaleSize = true
let isCheckingDuplicatedByName = true
let isCheckingDuplicatedByContent = true

// MARK: end of settings the script

let startDate = Date()

var searchUsingRegexPatterns: [String] = []
for usingType in usingTypes {
    switch usingType {
    case .custom(let pattern):
        searchUsingRegexPatterns.append(pattern)
    case .swiftUI:
        searchUsingRegexPatterns.append(#"\bImage\(\s*"(.*)"\s*\)"#)
    case .uiKit:
        searchUsingRegexPatterns.append(#"\bUIImage\(\s*named:\s*"(.*)"\s*\)"#)
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

extension String {
    
    var linesCount: Int {
        return self.reduce(into: 1) { (count, letter) in
             if letter == "\n" {      // This treats CRLF as one "letter", contrary to UnicodeScalars
                count += 1
             }
        }
    }
    
    var scale: Int? {
        guard (self as NSString).contains("x") else {
            return nil
        }
        return Int(self.dropLast(1))
    }
}

extension NSImage{
    var pixelSize: NSSize?{
        if let rep = self.representations.first{
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
let imageScales = (1...3)
class ImageInfo {
    struct File {
        let path: String
        // if nil that vector-universal
        let scale: Int?
    }
    
    let name: String
    var files: [File]
    
    var hash: String = ""
    
    init(name: String, path: String, scale: Int?) {
        self.name = name
        self.files = [File(path: path, scale: scale)]
    }
    
    private struct AssetContents: Decodable {
        let images: [Image]
        struct Image : Decodable {
            let filename: String?
            let scale: String?
        }
    }
    
    private struct FolderContents: Decodable {
        let properties: Properties?
        struct Properties : Decodable {
            let isNamespace: Bool
            
            enum CodingKeys: String, CodingKey {
                case isNamespace = "provides-namespace"
            }
        }
    }
    
    static func load<T: Decodable>(_ type: T.Type, for folder: String) -> T? {
        let contentsPath = imagesPath + "/" + folder + "/Contents.json"
        guard let contentsData = NSData(contentsOfFile: contentsPath) as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: contentsData)
    }
    
    static func processFound(path: String) {
        var isAsset = false
        var folderName = ""
        let components = path.split(separator: "/")
        for (index, component) in components.enumerated() {
            if component.hasSuffix(assetExtension) {
                isAsset = true
            } else {
                if isAsset == false { // only for asset
                    continue
                }
                if component.hasSuffix(imagesetExtension) { // it is asset
                    let name = (component as NSString).substring(to: component.count - imagesetExtension.count)
                    if let contents = load(AssetContents.self, for: components[0..<index + 1].joined(separator: "/"))
                    {
                        //print(contents)
                        let fileName = (path as NSString).lastPathComponent
                        let scale: Int? = contents.images.reduce(into: nil) { (result, image) in
                            if image.filename == fileName {
                                result = image.scale?.scale
                            }
                        }
                        processFound(name: folderName + name, path: path, scale: scale)
                    } else {
                        printError(filePath: path, message: "Not readed scale information", isWarning: true)
                        
                        processFound(name: folderName + name, path: path, scale: nil)
                    }
                    break
                } else if component.hasSuffix(appIconExtension) { // it is Application icon and we will ignore it
                    return
                } else {
                    // It is folder, but way???
                    if let contents = load(FolderContents.self, for: components[0..<index + 1].joined(separator: "/"))
                    {
                        if contents.properties?.isNamespace ?? false {
                            folderName += component + "/"
                        }
                    }
                }
            }
        }
        if !isAsset {
            let name = nameOfImageFile(path: path)
            processFound(name: name.path, path: path, scale: name.scale)
        }
    }
    
    static private func processFound(name: String, path: String, scale: Int?) {
        if let existImage = foundedImages[name] {
            existImage.files.append(File(path: path, scale: scale))
        } else {
            foundedImages[name] = ImageInfo(name: name, path: path, scale: scale)
        }
    }
    
    static func nameOfImageFile(path: String) -> (path: String, scale: Int) {
        return pathOfImageFile(path: (path as NSString).lastPathComponent)
    }
    
    static func pathOfImageFile(path: String) -> (path: String, scale: Int) {
        var name = (path as NSString).deletingPathExtension
        var scale = 1
        for imageScale in imageScales {
            let scaleSuffix = "@\(imageScale)x"
            if name.hasSuffix(scaleSuffix) {
                name = String(name.dropLast(scaleSuffix.count))
                scale = imageScale
                break
            }
        }
        return (name, scale)
    }
    
    static func isTheSameImage(path1: String, path2: String) -> Bool {
        pathOfImageFile(path: path1).path == pathOfImageFile(path: path2).path
    }
    
    var assetPath: String? {
        var result: String? = nil
        for imageFile in files {
            let components = imageFile.path.split(separator: "/")
            if components.count == 0 { // it just image
                return nil
            } else {
                for component in components {
                    if component.hasSuffix(imagesetExtension) { // it is asset
                        var name = (imageFile.path as NSString).components(separatedBy: imagesetExtension).first ?? ""
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
        for file in self.files {
            let imageFilePath = "\(imagesPath)/\(file.path)"
            printError(filePath: imageFilePath, message: message)
        }
    }
    
    func checkDuplicateByName() {
        guard files.count > 1 else {
            return
        }
        if assetPath == nil {
            var isDifferentImages = false
            for file in files {
                if !Self.isTheSameImage(path1: files.first?.path ?? "", path2: file.path) {
                    isDifferentImages = true
                    break
                }
            }
            if isDifferentImages {
                error(with: "Duplicated image with name: '\(name)'")
            }
        }
    }
    
    func checkImageSize() {
        var scaledSize: (width: Int, height: Int)? = nil
        for file in files {
            let imageFilePath = "\(imagesPath)/\(file.path)"
            if let image = NSImage(contentsOfFile: imageFilePath), let pixelSize = image.pixelSize
            {
                let size = image.size
                if pixelSize.height == 0, pixelSize.width == 0{
                    if size.height != 0, size.width != 0 {
                        // it's okey just vector image
                        // but can problems
                        if let scale = file.scale {
                            printError(filePath: imageFilePath, message: "It is vector image. But it has scale = \(scale)", isWarning: true)
                        }
                    } else {
                        printError(filePath: imageFilePath, message: "Image has zero size", isWarning: true)
                    }
                } else {
                    if let scale = file.scale {
                        if Int(pixelSize.height) % scale != 0 || Int(pixelSize.width) % scale != 0 {
                            printError(filePath: imageFilePath, message: "Image has floating size from scaled images. Real size is \(pixelSize) and scale = \(scale)")
                        } else {
                            let newScaledSize = (Int(pixelSize.width) / scale, Int(pixelSize.height) / scale)
                            if let scaledSize = scaledSize {
                                if scaledSize != newScaledSize {
                                    printError(filePath: imageFilePath, message: "Image has different size for scaled group. Real size is \(pixelSize) with scale = \(scale) but expected \(NSSize(width: scaledSize.0 * scale, height:scaledSize.1 * scale))")
                                }
                            } else {
                                scaledSize = newScaledSize
                            }
                        }
                    }
                }
            } else {
                printError(filePath: imageFilePath, message: "That is not image", isWarning: true)
            }
        }
    }
    
    func calculateData() -> Data? {
        var maxScale = 0
        var result: Data? = nil
        for file in files {
            let imageFilePath = "\(imagesPath)/\(file.path)"
            if let image = NSImage(contentsOfFile: imageFilePath), let pixelSize = image.pixelSize
            {
                let size = image.size
                if pixelSize.height == 0, pixelSize.width == 0{
                    if size.height != 0, size.width != 0 {
                        // it's okey just vector image
                        var imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                        let cgImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
                        if let data = cgImage?.png {
                            result = data
                            maxScale = 1
                        }
                    }
                } else {
                    if let scale = file.scale {
                        // calculate hash
                        if maxScale < scale {
                            var imageRect = CGRect(x: 0, y: 0, width: Int(pixelSize.width) / scale, height: Int(pixelSize.height) / scale)
                            let cgImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
                            if let data = cgImage?.png {
                                result = data
                                maxScale = scale
                            }
                        }
                    }
                }
            }
        }
        return result
    }
}

let imageFileEnumerator = FileManager.default.enumerator(atPath: imagesPath)
let pdfRasterPattern = #".*\/[Ii]mage.*"#
let pdfRasterRegex = try? NSRegularExpression(pattern: pdfRasterPattern, options: [])
var foundedImages: [String: ImageInfo] = [:]

while let imageFileName = imageFileEnumerator?.nextObject() as? String {
    let fileExtension = (imageFileName as NSString).pathExtension
    if imageExtensions.contains(fileExtension)
    {
        
        let imageFilePath = "\(imagesPath)/\(imageFileName)"
        
        ImageInfo.processFound(path: imageFileName)

        let fileSize = fileSize(fromPath: imageFilePath)

        if vectorExtensions.contains(fileExtension) {
            if isCheckingFileSize, fileSize > maxPdfSize {
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
            if isCheckingFileSize, fileSize > maxPngSize {
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
var usedImages: [String] = []
for regexPattern in searchUsingRegexPatterns {
    let regex = try? NSRegularExpression(pattern: regexPattern, options: [])
    if regex == nil {
        printError(filePath: #file, message: "Not right pattern for regex: \(regexPattern)", line: #line)
    }
    let swiftFileEnumerator = FileManager.default.enumerator(atPath: sourcePath)
    while let sourceFileName = swiftFileEnumerator?.nextObject() as? String {
        // checks the extension
        if sourceFileName.hasSuffix(".swift") || sourceFileName.hasSuffix(".m") || sourceFileName.hasSuffix(".mm") {
            let sourceFilePath = "\(sourcePath)/\(sourceFileName)"
            if let string = try? String(contentsOfFile: sourceFilePath, encoding: .utf8) {
                let range = NSRange(location: 0, length: (string as NSString).length)
                regex?.enumerateMatches(in: string,
                                        options: [],
                                        range: range) { result, _, _ in
                    addUsedImage(from: string, result: result, path: sourceFilePath)
                }
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
    if foundedImages[value] == nil, ignoredUndefinedImages.contains(value) == false {
        let line = (string as NSString).substring(with: NSRange(location: 0, length: result.range(at: 0).location)).linesCount
        
        printError(filePath: path, message: "Not found image with name '\(value)'", line: line)
    }
}

let unusedImages = Set(foundedImages.keys).subtracting(usedImages).subtracting(ignoredUnusedImages)
for unusedImage in unusedImages {
    if let imageInfo = foundedImages[unusedImage] {
        imageInfo.error(with: "File unused from code.")
    }
}

let images: [ImageInfo] = foundedImages.values.map{ $0 }
for imageInfo in images {
    if isCheckingDuplicatedByName {
        imageInfo.checkDuplicateByName()
    }
    if isCheckingScaleSize {
        imageInfo.checkImageSize()
    }
    if isCheckingDuplicatedByContent {
        if let data = imageInfo.calculateData() {
            imageInfo.hash = "\(data.count)"
        }
    }
}

if isCheckingDuplicatedByContent {
    for (index, imageInfo1) in images.enumerated() {
//        let file1 = imageInfo1.files.first!
//        let imageFilePath1 = "\(imagesPath)/\(file1.path)"
//        print(imageFilePath1)
//        if imageInfo1.hash.isEmpty{
//            print("nil")
//        } else {
//            print(imageInfo1.hash)
//        }
        
        for i in index+1..<images.count {
            let imageInfo2 = images[i]
            if imageInfo1.hash.isEmpty == false, imageInfo1.hash == imageInfo2.hash, imageInfo1.calculateData() == imageInfo2.calculateData() {
                let file1 = imageInfo1.files.first!
                let imageFilePath1 = "\(imagesPath)/\(file1.path)"
                let file2 = imageInfo2.files.first!
                let imageFilePath2 = "\(imagesPath)/\(file2.path)"
                printError(filePath: imageFilePath1, message: "Duplicate by content with '\(imageFilePath2)'")
            }
        }
    }
}

for image in images {
    print(image.name)
}

print("Number of images: \(foundedImages.values.reduce(into: 0){ $0 += $1.files.count } )")
print("Number of warnings: \(warningsCount)")
print("Number of errors: \(errorsCount)")
print("Time: \(Date().timeIntervalSince(startDate)) sec.")

if errorsCount > 0 {
    exit(1)
}
