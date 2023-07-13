#!/usr/bin/env xcrun --sdk macosx swift

import Foundation
import AppKit

/**
 ImageLinter.swift
 version 1.7

 Created by Sergey Balalaev on 23.09.22.
 Copyright (c) 2022-2023 ByteriX. All rights reserved.

 Script allows:
 1. Checking size (file and image) of vector(PDF) and rastor(PNG/JPEG) files
 2. Catch raster from PDF or SVG
 3. Checking unused image files
 4. Search undefined images
 5. Comparing scaled images size
 6. Checking duplicate images by name
 7. Checking duplicate images by content (but identical)
 8. Search empty and broken asset images

 Using from build phase:
 ${SRCROOT}/Scripts/ImageLinter.swift
 */

/// For enable or disable this script
let isEnabled = true

/// Path to folder with images files. For example "/YouProject/Resources/Images"
let relativeImagesPath = UserDefaults.standard.string(forKey: "imagesPath")!

/// Path of the source folder which will used in searching for localization keys you actually use in your project. For Example "/YouProject/Source"
let relativeSourcePath = UserDefaults.standard.string(forKey: "sourcePath")!

/// Using localizations type from code. If you use custom you need define regex pattern
enum UsingType {
    case swiftUI
    case uiKit
    case swiftGen(enumName: String = "Asset")
    case custom(pattern: String)
}

/// yuo can use many types
let usingTypes: [UsingType] = [
    .swiftGen(), .swiftUI, .uiKit
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

let rastorExtensions = ["png", "jpg", "jpeg"]
let vectorExtensions = ["pdf", "svg"]
let rastorSetExtensions = Set<String>(rastorExtensions.map{$0.uppercased()})
let vectorSetExtensions = Set<String>(vectorExtensions.map{$0.uppercased()})
let imageSetExtensions = rastorSetExtensions.union(vectorSetExtensions)

let sourcesExtensions = ["swift", "mm", "m"]
let resourcesExtensions = ["storyboard", "xib"]
let sourcesSetExtensions = Set<String>(sourcesExtensions.map{$0.uppercased()})
let resourcesSetExtensions = Set<String>(resourcesExtensions.map{$0.uppercased()})

// If you wan't show double errors/warnings for all files of an image change this to false
let isAllFilesErrorShowing = false

// Maximum size of Vector files
let maxVectorFileSize: UInt64 = 20_000
let maxVectorImageSize: CGSize = CGSize(width: 100, height: 100)

// Maximum size of Rastor files
let maxRastorFileSize: UInt64 = 200_000
let maxRastorImageSize: CGSize = CGSize(width: 1000, height: 1000)

let isCheckingFileSize = true
let isCheckingImageSize = true
let isCheckingPdfVector = true
let isCheckingSvgVector = true
let isCheckingScaleSize = true
let isCheckingDuplicatedByName = true
let isCheckingDuplicatedByContent = true

/// Your project should compile for one or more platform. This need for detect quality of images.
enum TargetPlatform {
    case iOS
    case iPadOS
    case macOS
    case tvOS
    case visionOS
    case watchOS
}

/// yuo can use many platforms
let targetPlatforms: [TargetPlatform] = [.iOS]

// MARK: end of settings the script

let startDate = Date()

var searchUsingRegexPatterns: [String] = []
var isSwiftGen = false
for usingType in usingTypes {
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
for targetPlatform in targetPlatforms {
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

if isEnabled == false {
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

let imagesPath = FileManager.default.currentDirectoryPath + relativeImagesPath
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

private struct AssetContents: Decodable {
    let images: [Image]
    struct Image: Decodable {
        let filename: String?
        let scale: String?
    }
}

private struct FolderContents: Decodable {
    let properties: Properties?
    struct Properties: Decodable {
        let isNamespace: Bool
        
        enum CodingKeys: String, CodingKey {
            case isNamespace = "provides-namespace"
        }
    }
}

func load<T: Decodable>(_ type: T.Type, for folder: String) -> T? {
    let contentsPath = imagesPath + "/" + folder + "/Contents.json"
    guard let contentsData = NSData(contentsOfFile: contentsPath) as? Data else {
        return nil
    }
    return try? JSONDecoder().decode(type, from: contentsData)
}

let imagesetExtension = ".imageset"
let appIconExtension = ".appiconset"
let assetExtension = ".xcassets"

class ImageInfo {
    struct File {
        let path: String
        // if nil that vector-universal
        let scale: Int?
    }
    
    enum ImageType {
        case undefined
        case vector
        case rastor
        case mixed
    }
    
    let name: String
    var files: [File]
    
    var hash: String = ""
    
    var type: ImageType = .undefined
    
    func setAndCheckType(newType: ImageType, filePath: String){
        if type != .undefined, newType != type {
            printError(
                filePath: filePath,
                message: "The image with name '\(name)' has different types of files: \(newType) and \(type)"
            )
            type = .mixed
        } else {
            type = newType
        }
    }
    
    init(name: String, path: String, scale: Int?) {
        self.name = name
        files = [File(path: path, scale: scale)]
    }
    
    static func processFound(path: String) -> ImageInfo? {
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
                    if let contents = load(AssetContents.self, for: components[0..<index + 1].joined(separator: "/")) {
                        let fileName = (path as NSString).lastPathComponent
                        let scale: Int? = contents.images.reduce(into: nil) { result, image in
                            if image.filename == fileName {
                                result = image.scale?.scale
                            }
                        }
                        return processFound(name: folderName + name, path: path, scale: scale)
                    } else {
                        printError(filePath: path, message: "Not readed scale information. Found for image '\(name)'", isWarning: true)

                        return processFound(name: folderName + name, path: path, scale: nil)
                    }
                    //break
                } else if component.hasSuffix(appIconExtension) { // it is Application icon and we will ignore it
                    return nil
                } else {
                    // It is folder, but way???
                    if let contents = load(FolderContents.self, for: components[0..<index + 1].joined(separator: "/")) {
                        if contents.properties?.isNamespace ?? false {
                            folderName += component + "/"
                        }
                    }
                }
            }
        }
        if !isAsset {
            let name = nameOfImageFile(path: path)
            return processFound(name: name.path, path: path, scale: name.scale)
        }
        return nil
    }

    private static func processFound(name: String, path: String, scale: Int?) -> ImageInfo {
        var key = name
        if isSwiftGen {
            key = name
                .split(separator: "/")
                .map { String($0) }
                .swiftGen()
                .joined(separator: ".")
        }
        if let existImage = foundedImages[key] {
            existImage.files.append(File(path: path, scale: scale))
            return existImage
        } else {
            let result = ImageInfo(name: key, path: path, scale: scale)
            foundedImages[key] = result
            return result
        }
    }
    
    static func nameOfImageFile(path: String) -> (path: String, scale: Int) {
        return pathOfImageFile(path: (path as NSString).lastPathComponent)
    }
    
    static func pathOfImageFile(path: String) -> (path: String, scale: Int) {
        var name = (path as NSString).deletingPathExtension
        var scale = 1
        for imageScale in allImageScales {
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
        var result: String?
        for imageFile in files {
            let components = imageFile.path.split(separator: "/")
            if components.isEmpty { // it just image
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

    func error(with message: String) {
        for file in files {
            let imageFilePath = "\(imagesPath)/\(file.path)"
            printError(filePath: imageFilePath, message: message)
            guard isAllFilesErrorShowing else {
                break
            }
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
    
    static let svgSearchWidthHeightRegex = try! NSRegularExpression(pattern: #"<svg.*width="(.*?)p?t?".*height="(.*?)p?t?".*>"#, options: [])
    static let svgSearchHeightWidthRegex = try! NSRegularExpression(pattern: #"<svg.*height="(.*?)p?t?".*width="(.*?)p?t?".*>"#, options: [])
    
    func checkImageSizeAndDetectType() {
        var scaledSize: (width: Int, height: Int)?
        for file in files {
            let imageFilePath = "\(imagesPath)/\(file.path)"
            if let image = NSImage(contentsOfFile: imageFilePath) {
                let pixelSize = image.pixelSize ?? NSSize()
                let size = image.size
                if pixelSize.height == 0, pixelSize.width == 0 {
                    if size.height != 0, size.width != 0 {
                        setAndCheckType(newType: .vector, filePath: imageFilePath)
                        // it's okey just vector image
                        // but can problems
                        if let scale = file.scale {
                            printError(
                                filePath: imageFilePath,
                                message: "It is vector image. But it has scale = \(scale). Found for image '\(name)'",
                                isWarning: true
                            )
                        }
                        if size.width > maxVectorImageSize.width || size.height > maxVectorImageSize.height {
                            printError(
                                filePath: imageFilePath,
                                message: "The vector image has very biggest image size (\(size.width), \(size.height)). Max image size for vector is (\(maxVectorImageSize.width), \(maxVectorImageSize.height)). Found for image '\(name)'"
                            )
                        }
                    } else {
                        printError(filePath: imageFilePath, message: "Image has zero size. Found for image '\(name)'", isWarning: true)
                    }
                } else {
                    if let scale = file.scale {
                        setAndCheckType(newType: .rastor, filePath: imageFilePath)
                        if Int(pixelSize.width) % scale != 0 || Int(pixelSize.height) % scale != 0 {
                            let newScaledSize: (width: Double, height: Double) = (Double(pixelSize.width) / Double(scale), Double(pixelSize.height) / Double(scale))
                            printError(
                                filePath: imageFilePath,
                                message: "Image has floating size from scaled images. Real size is \(pixelSize) and scale = \(scale). Please check the file, it must have integer size after apply this scale. But you actually have \(newScaledSize). Found for image '\(name)'."
                            )
                        } else {
                            let newScaledSize: (width: Int, height: Int) = (Int(pixelSize.width) / scale, Int(pixelSize.height) / scale)
                            if let scaledSize = scaledSize {
                                if scaledSize != newScaledSize {
                                    printError(
                                        filePath: imageFilePath,
                                        message: "Image has different size for scaled group. Real size is \(pixelSize) with scale = \(scale) but expected \(NSSize(width: scaledSize.0 * scale, height: scaledSize.1 * scale)). Found for image '\(name)'"
                                    )
                                }
                            } else {
                                scaledSize = newScaledSize
                            }
                            if CGFloat(newScaledSize.width) > maxRastorImageSize.width || CGFloat(newScaledSize.height) > maxRastorImageSize.height{
                                printError(
                                    filePath: imageFilePath,
                                    message: "The rastor image has very biggest image size (\(newScaledSize.width), \(newScaledSize.height)). Max image size for rastor is (\(maxRastorImageSize.width), \(maxRastorImageSize.height)). Found for image '\(name)'"
                                )
                            }
                        }
                    }
                }
            } else if imageFilePath.uppercased().hasSuffix("SVG") { // NSImage can not support SVG files. You can use only from Assets
                setAndCheckType(newType: .vector, filePath: imageFilePath)
                if let scale = file.scale {
                    printError(
                        filePath: imageFilePath,
                        message: "It is vector image. But it has scale = \(scale). Found for image '\(name)'",
                        isWarning: true
                    )
                }

                // Need parse SVG and extract width / height for checking
                // examples:
                // vector: <svg width="37pt" height="37pt" viewBox="0 0 37 37" >
                // rastor: <svg width="50" height="50" viewBox="636,559,50,50">
                if isCheckingImageSize {
                    if let string = try? String(contentsOfFile: imageFilePath, encoding: .ascii) {
                        let range = NSRange(location: 0, length: string.count)
                        
                        if let result = Self.svgSearchWidthHeightRegex.firstMatch(in: string, options: [], range: range) {
                            print("VALUE!!!")
                            let _ = (1...result.numberOfRanges - 1).map { index in
                                let value = (string as NSString).substring(with: result.range(at: index))
                                print("VALUE=\(value)")
                            }
                        }
                    } else {
                        printError(filePath: imageFilePath, message: "Can not parse SVG file. Found for image '\(name)'")
                    }
                }
            } else {
                printError(filePath: imageFilePath, message: "That is not image. Found for image '\(name)'", isWarning: true)
            }
        }
        if type == .vector, files.count > 1 {
            printError(
                filePath: files.first?.path ?? "",
                message: "The vector image with name '\(name)' has \(files.count) files",
                isWarning: true
            )
        } else if type == .rastor {
            // Analysis scales with dependency on target platforms
            let currentScalesDictionary : Dictionary<Int, File> = files.reduce(Dictionary<Int, File>()) { result, file in
                if let scale = file.scale {
                    var newResult = result
                    newResult[scale] = file
                    return newResult
                } else {
                    printError(
                        filePath: file.path,
                        message: "The rastor image with name '\(name)' has undefined scale. May be it's vector?",
                        isWarning: true
                    )
                }
                return result
            }
            let currentScales = Set<Int>(currentScalesDictionary.keys)
            let extraScales = currentScales.subtracting(targetScales)
            for extraScale in extraScales {
                printError(
                    filePath: currentScalesDictionary[extraScale]?.path ?? "",
                    message: "The rastor image with name '\(name)' has extra scale=\(extraScale) for current platforms target (\(targetPlatforms)).",
                    isWarning: true
                )
            }
            let missingScales = targetScales.subtracting(currentScales)
            if missingScales.count > 0 {
                printError(
                    filePath: files.first?.path ?? "",
                    message: "The rastor image with name '\(name)' has missing scale=\(missingScales). You need add images with this scales for correct showing at selected target platforms = \(targetPlatforms).",
                    isWarning: true
                )
            }
        }
    }

    func calculateData() -> Data? {
        var maxScale = 0
        var result: Data?
        for file in files {
            let imageFilePath = "\(imagesPath)/\(file.path)"
            if let image = NSImage(contentsOfFile: imageFilePath), let pixelSize = image.pixelSize {
                let size = image.size
                if pixelSize.height == 0, pixelSize.width == 0 {
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
                            var imageRect = CGRect(
                                x: 0,
                                y: 0,
                                width: Int(pixelSize.width) / scale,
                                height: Int(pixelSize.height) / scale
                            )
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
let svgRasterPattern = #".*<image .*"#
let svgRasterRegex = try? NSRegularExpression(pattern: svgRasterPattern, options: [])

var foundedImages: [String: ImageInfo] = [:]

while let imageFileName = imageFileEnumerator?.nextObject() as? String {
    let fileExtension = (imageFileName as NSString).pathExtension.uppercased()
    if imageSetExtensions.contains(fileExtension) {
        let imageFilePath = "\(imagesPath)/\(imageFileName)"

        if let imageInfo = ImageInfo.processFound(path: imageFileName){
            
            let fileSize = fileSize(fromPath: imageFilePath)
            
            if vectorSetExtensions.contains(fileExtension) {
                if isCheckingFileSize, fileSize > maxVectorFileSize {
                    printError(
                        filePath: imageFilePath,
                        message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: maxVectorFileSize)). Found for image '\(imageInfo.name)'"
                    )
                }
                
                if isCheckingPdfVector || isCheckingSvgVector {
                    if let string = try? String(contentsOfFile: imageFilePath, encoding: .ascii) {
                        let range = NSRange(location: 0, length: string.count)
                        if isCheckingPdfVector, pdfRasterRegex?.firstMatch(in: string, options: [], range: range) != nil {
                            printError(filePath: imageFilePath, message: "PDF File is not vector. Found for image '\(imageInfo.name)'")
                        }
                        if isCheckingSvgVector, svgRasterRegex?.firstMatch(in: string, options: [], range: range) != nil {
                            printError(filePath: imageFilePath, message: "SVG File is not vector. Found for image '\(imageInfo.name)'")
                        }
                    } else {
                        printError(filePath: imageFilePath, message: "Can not parse Vector file. Found for image '\(imageInfo.name)'")
                    }
                }
            } else if rastorSetExtensions.contains(fileExtension) {
                if isCheckingFileSize, fileSize > maxRastorFileSize {
                    printError(
                        filePath: imageFilePath,
                        message: "File size (\(covertToString(fileSize: fileSize))) of the image is very biggest. Max file size is \(covertToString(fileSize: maxRastorFileSize)). Found for image '\(imageInfo.name)'"
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

let sourcePath = FileManager.default.currentDirectoryPath + relativeSourcePath
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
    if sourcesSetExtensions.contains(fileExtension) {
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
    } else if resourcesSetExtensions.contains(fileExtension) { // checks the extension to resource
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
    if foundedImages[value] == nil, ignoredUndefinedImages.contains(value) == false {
        let line = (string as NSString).substring(with: NSRange(location: 0, length: result.range(at: 0).location)).linesCount
        
        printError(filePath: path, message: "Not found image with name '\(value)'", line: line)
    }
}

let unusedImages = Set(foundedImages.keys).subtracting(usedImages).subtracting(ignoredUnusedImages)
for unusedImage in unusedImages {
    if let imageInfo = foundedImages[unusedImage] {
        imageInfo.error(with: "File unused from code. Found for image '\(imageInfo.name)'")
    }
}

let images: [ImageInfo] = foundedImages.values.map { $0 }
for imageInfo in images {
    if isCheckingDuplicatedByName {
        imageInfo.checkDuplicateByName()
    }
    if isCheckingScaleSize {
        imageInfo.checkImageSizeAndDetectType()
    }
    if isCheckingDuplicatedByContent {
        if let data = imageInfo.calculateData() {
            imageInfo.hash = "\(data.count)"
        }
    }
}

if isCheckingDuplicatedByContent {
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
