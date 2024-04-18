//
//  ImageInfo.swift
//  
//
//  Created by Sergey Balalaev on 03.04.2024.
//

import Foundation
import AppKit

struct AssetContents: Decodable {
    let images: [Image]
    struct Image: Decodable {
        let filename: String?
        let scale: String?
    }
}

struct FolderContents: Decodable {
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
        if let existImage = foundedImages[name] {
            existImage.files.append(File(path: path, scale: scale))
            return existImage
        } else {
            let result = ImageInfo(name: name, path: path, scale: scale)
            foundedImages[name] = result
            if isSwiftGen {
                foundedSwiftGenMirrorImages[name.swiftGenKey()] = name
            }
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
            guard settings.isAllFilesErrorShowing else {
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
                        if size.width > settings.maxVectorImageSize.width || size.height > settings.maxVectorImageSize.height {
                            printError(
                                filePath: imageFilePath,
                                message: "The vector image has very biggest image size (\(size.width), \(size.height)). Max image size for vector is (\(settings.maxVectorImageSize.width), \(settings.maxVectorImageSize.height)). Found for image '\(name)'"
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
                            if CGFloat(newScaledSize.width) > settings.maxRastorImageSize.width || CGFloat(newScaledSize.height) > settings.maxRastorImageSize.height{
                                printError(
                                    filePath: imageFilePath,
                                    message: "The rastor image has very biggest image size (\(newScaledSize.width), \(newScaledSize.height)). Max image size for rastor is (\(settings.maxRastorImageSize.width), \(settings.maxRastorImageSize.height)). Found for image '\(name)'"
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
                if settings.isCheckingImageSize {
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
                    message: "The rastor image with name '\(name)' has extra scale=\(extraScale) for current platforms target (\(settings.targetPlatforms)).",
                    isWarning: true
                )
            }
            let missingScales = targetScales.subtracting(currentScales)
            if missingScales.count > 0 {
                printError(
                    filePath: files.first?.path ?? "",
                    message: "The rastor image with name '\(name)' has missing scale=\(missingScales). You need add images with this scales for correct showing at selected target platforms = \(settings.targetPlatforms).",
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
