//
//  Settings.swift
//  
//
//  Created by Sergey Balalaev on 02.04.2024.
//

import Foundation

struct Settings {
    
    /// For enable or disable this script
    var isEnabled = true

    private(set) var dir: String = defaultDir

    /// Multipath  to folders with images you actually use in your project. For Example ["/YouProject/Resources/Images",  "/OtherProject"]
    private(set) var relativeImagesPaths: [String] = []

    /// Multipath  of the sources folders which will used in searching for images you actually use in your project. For Example ["/YouProject/Source",  "/OtherProject"]
    var relativeSourcePaths: [String] = []

    /// Using images type from code. If you use custom you need define regex pattern
    enum UsingType {
        case swiftUI
        case uiKit
        case uiKitLiteral
        case swiftGen(enumName: String = "Asset")
        case custom(pattern: String, isSwiftGen: Bool)
    }

    /// you can use many types of images usage
    var usingTypes: [UsingType] = [
        .swiftGen(),
        .swiftUI,
        .uiKit,
        .uiKitLiteral
    ]

    /// Patterns of checking of the image name
    enum CheckingNameType {
        case firstUpperCase(message: String = "Name should start with uppercase")
        case camelCase(message: String = "Camel case support only")
        case sneak_case (message: String = "Sneak case support only")
        case kebab_case (message: String = "Kebab case support only")
        case custom (pattern: String, message: String = "Custom name checking")
    }

    /// you can check image name with a set of patterns
    var checkingNameTypes: [CheckingNameType] = []

    /**
     If you want to exclude unused image from checking, you can define they this

     Example:
      let ignoredUnusedImages = [
         "ApplicationPoster"
      ]
     */
    var ignoredUnusedImages: Set<String> = [ ]
    var ignoredUndefinedImages: Set<String> = [ ]

    var rastorExtensions = Set<String>(["png", "jpg", "jpeg"].map{$0.uppercased()})
    var vectorExtensions = Set<String>(["pdf", "svg"].map{$0.uppercased()})

    var sourcesExtensions = Set<String>(["swift", "mm", "m"].map{$0.uppercased()})
    var resourcesExtensions = Set<String>(["storyboard", "xib"].map{$0.uppercased()})

    // If you wan't show double errors/warnings for all files of an image change this to false
    var isAllFilesErrorShowing = false

    // Maximum size of Vector files
    var maxVectorFileSize: UInt64 = 20_000
    var maxVectorImageSize: CGSize = CGSize(width: 100, height: 100)

    // Maximum size of Rastor files
    var maxRastorFileSize: UInt64 = 200_000
    var maxRastorImageSize: CGSize = CGSize(width: 1000, height: 1000)

    var isCheckingFileSize = true
    var isCheckingImageSize = true
    var isCheckingPdfVector = true
    var isCheckingSvgVector = true
    var isCheckingScaleSize = true
    var isCheckingDuplicatedByName = true
    var isCheckingDuplicatedByContent = true

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
    var targetPlatforms: [TargetPlatform] = [.iOS]

    init(){
        load()
    }

}

extension Settings {

    private static let extensions = ["yml", "yaml"]
    private static let fileName = "imagelinter"
    private static let defaultDir: String = pathWithSlash(FileManager.default.currentDirectoryPath)

    private enum Key: String {
        case isEnabled
        case relativeImagesPaths
        case relativeImagesPath
        case relativeSourcePaths
        case relativeSourcePath

        case usingTypes
        case checkingNameTypes

        case ignoredUnusedImages
        case ignoredUndefinedImages

        case rastorExtensions
        case vectorExtensions

        case sourcesExtensions
        case resourcesExtensions

        case isAllFilesErrorShowing

        case maxVectorFileSize
        case maxVectorImageSize

        case maxRastorFileSize
        case maxRastorImageSize


        case isCheckingFileSize
        case isCheckingImageSize
        case isCheckingPdfVector
        case isCheckingSvgVector
        case isCheckingScaleSize
        case isCheckingDuplicatedByName
        case isCheckingDuplicatedByContent

        case targetPlatforms

        enum UsingType: String {
            case swiftUI
            case uiKit
            case uiKitLiteral
            case swiftGen
            case custom
        }

        enum CheckingNameType: String {
            case firstUpperCase
            case camelCase
            case sneak_case
            case kebab_case
            case custom

            func convert(message: String?) -> Settings.CheckingNameType {
                if let message {
                    switch self {
                        case .firstUpperCase: return .firstUpperCase(message: message)
                        case .camelCase: return .camelCase(message: message)
                        case .sneak_case: return .sneak_case(message: message)
                        case .kebab_case: return .kebab_case(message: message)
                        case .custom: return .custom(pattern: "", message: message)
                    }
                } else {
                    switch self {
                        case .firstUpperCase: return .firstUpperCase()
                        case .camelCase: return .camelCase()
                        case .sneak_case: return .sneak_case()
                        case .kebab_case: return .kebab_case()
                        case .custom: return .custom(pattern: "")
                    }
                }
            }
        }

        enum TargetPlatform: String {
            case iOS
            case iPadOS
            case macOS
            case tvOS
            case visionOS
            case watchOS
        }
    }

    fileprivate mutating func load() {
        var dirs = [Self.defaultDir]

        var argIndex = 1
        while argIndex < CommandLine.arguments.count {
            if CommandLine.arguments[argIndex] == "--settingsPath" {
                argIndex += 1
                if argIndex < CommandLine.arguments.count {
                    dirs.append(CommandLine.arguments[argIndex])
                }
            }
            argIndex += 1
        }
        for dir in dirs {
            for ext in Self.extensions {
                load(dir: dir, ext: ext)
            }
        }
    }

    private static func pathWithSlash(_ path: String) -> String {
        var result = path
        if !result.hasSuffix("/") {
            result = result + "/"
        }
        return result
    }

    fileprivate mutating func load(dir: String, ext: String) {

        let filePath = (dir as NSString).appendingPathComponent(Self.fileName + "." + ext)
        guard let stringData = try? String(contentsOfFile: filePath) else {
            print("Settings file '\(filePath)' not found")
            return
        }
        self.dir = dir
        print("Parse settings file '\(filePath)':")

        let lines = stringData.components(separatedBy: .newlines)

        var currentKey: Key? = nil
        var isStartKey: Bool = false
        var lineIndex = 0

        while lineIndex < lines.count {
            let line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
            lineIndex += 1

            if line.hasPrefix("#") {
                continue
            }

            var currentValue: String? = nil
            if let value = Self.getArrayValue(line: line) {
                currentValue = value
            } else if let object = Self.getObject(line: line) {
                if let key = Key(rawValue: object.name) {
                    currentKey = key
                    currentValue = object.value
                    isStartKey = true
                }
            }

            func getSize(defaultSize: CGSize) -> CGSize {
                var width = defaultSize.width
                var height = defaultSize.height

                while lineIndex < lines.count
                {
                    let line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                    if line.hasPrefix("#") == false,
                       let object = Self.getObject(line: line)
                    {
                        if object.name == "width" {
                            width = Double(object.value) ?? defaultSize.width
                        } else if object.name == "height" {
                            height = Double(object.value) ?? defaultSize.height
                        } else {
                            break
                        }
                    }
                    lineIndex += 1
                }

                return CGSize(width: width, height: height)
            }

            guard let currentKey else { continue }
            switch currentKey {
            case .isEnabled:
                if let value = currentValue, let isEnabled = Bool(value) {
                    self.isEnabled = isEnabled
                }
            case .relativeImagesPath, .relativeImagesPaths:
                if let value = currentValue, value != "" {
                    relativeImagesPaths.append(Self.pathWithSlash(value))
                }
            case .relativeSourcePath, .relativeSourcePaths:
                if let value = currentValue, value != "" {
                    relativeSourcePaths.append(Self.pathWithSlash(value))
                }
            case .usingTypes:
                if let value = currentValue, value.isEmpty == false {
                    if let object = Self.getObject(line: value), object.name == "case" {
                        if let usingType = Key.UsingType(rawValue: object.value) {
                            switch usingType {
                            case .swiftUI:
                                self.usingTypes.append(.swiftUI)
                            case .uiKit:
                                self.usingTypes.append(.uiKit)
                            case .uiKitLiteral:
                                self.usingTypes.append(.uiKitLiteral)
                            case .swiftGen:
                                guard lineIndex < lines.count else {
                                    break
                                }
                                let line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                if line.hasPrefix("#") == false,
                                   let object = Self.getObject(line: line),
                                   object.name == "enumName"
                                {
                                    lineIndex += 1
                                    self.usingTypes.append(.swiftGen(enumName: object.value))
                                }
                            case .custom:
                                guard lineIndex < lines.count else {
                                    break
                                }
                                var line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                var customPattern: String?
                                var customIsSwiftGen = false

                                // TODO: # needs just continue
                                while line.hasPrefix("#") == false,
                                   let object = Self.getObject(line: line),
                                   object.name == "pattern" || object.name == "isSwiftGen"
                                {
                                    lineIndex += 1
                                    if object.name == "pattern" {
                                        customPattern = object.value
                                    } else if object.name == "isSwiftGen", let isSwiftGen = Bool(object.value) {
                                        customIsSwiftGen = isSwiftGen
                                    }
                                    line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                }
                                if let customPattern {
                                    self.usingTypes.append(.custom(pattern: customPattern, isSwiftGen: customIsSwiftGen))
                                }
                            }
                        }
                    }
                } else if isStartKey {
                    self.usingTypes = []
                }
            case .checkingNameTypes:
                if let value = currentValue, value.isEmpty == false {
                    if let object = Self.getObject(line: value), object.name == "case" {
                        if let checkingNameType = Key.CheckingNameType(rawValue: object.value) {
                            switch checkingNameType {
                            case .firstUpperCase, .camelCase, .sneak_case, .kebab_case:
                                guard lineIndex < lines.count else {
                                    break
                                }
                                let line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                var customMessage: String?

                                if line.hasPrefix("#") == false,
                                   let object = Self.getObject(line: line),
                                   object.name == "message"
                                {
                                    lineIndex += 1
                                    customMessage = object.value
                                }
                                self.checkingNameTypes.append(checkingNameType.convert(message: customMessage))
                            case .custom:
                                guard lineIndex < lines.count else {
                                    break
                                }
                                var line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                var customPattern: String?
                                var customMessage: String?

                                // TODO: # needs just continue
                                while line.hasPrefix("#") == false,
                                   let object = Self.getObject(line: line),
                                   object.name == "pattern" || object.name == "message"
                                {
                                    lineIndex += 1
                                    if object.name == "pattern" {
                                        customPattern = object.value
                                    } else if object.name == "message" {
                                        customMessage = object.value
                                    }
                                    line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                }
                                if let customPattern {
                                    if let customMessage, customMessage.isEmpty == false {
                                        self.checkingNameTypes.append(.custom(pattern: customPattern, message: customMessage))
                                    } else {
                                        self.checkingNameTypes.append(.custom(pattern: customPattern))
                                    }
                                }
                            }
                        }
                    }
                } else if isStartKey {
                    self.checkingNameTypes = []
                }
            case .ignoredUnusedImages:
                if let value = currentValue, value.isEmpty == false {
                    self.ignoredUnusedImages.insert(value)
                } else if isStartKey {
                    self.ignoredUnusedImages = []
                }
            case .ignoredUndefinedImages:
                if let value = currentValue, value.isEmpty == false {
                    self.ignoredUndefinedImages.insert(value)
                } else if isStartKey {
                    self.ignoredUndefinedImages = []
                }
            case .rastorExtensions:
                if let value = currentValue, value.isEmpty == false {
                    self.rastorExtensions.insert(value.uppercased())
                } else if isStartKey {
                    self.rastorExtensions = []
                }
            case .vectorExtensions:
                if let value = currentValue, value.isEmpty == false {
                    self.vectorExtensions.insert(value.uppercased())
                } else if isStartKey {
                    self.vectorExtensions = []
                }
            case .sourcesExtensions:
                if let value = currentValue, value.isEmpty == false {
                    self.sourcesExtensions.insert(value.uppercased())
                } else if isStartKey {
                    self.sourcesExtensions = []
                }
            case .resourcesExtensions:
                if let value = currentValue, value.isEmpty == false {
                    self.resourcesExtensions.insert(value.uppercased())
                } else if isStartKey {
                    self.resourcesExtensions = []
                }
            case .isAllFilesErrorShowing:
                if let value = currentValue, let isAllFilesErrorShowing = Bool(value) {
                    self.isAllFilesErrorShowing = isAllFilesErrorShowing
                }
            case .maxVectorFileSize:
                if let value = currentValue, let maxVectorFileSize = UInt64(value) {
                    self.maxVectorFileSize = maxVectorFileSize
                }
            case .maxVectorImageSize:
                self.maxVectorImageSize = getSize(defaultSize: self.maxVectorImageSize)
                
            case .maxRastorFileSize:
                if let value = currentValue, let maxRastorFileSize = UInt64(value) {
                    self.maxRastorFileSize = maxRastorFileSize
                }
            case .maxRastorImageSize:
                self.maxRastorImageSize = getSize(defaultSize: self.maxRastorImageSize)

            case .isCheckingFileSize:
                if let value = currentValue, let isCheckingFileSize = Bool(value) {
                    self.isCheckingFileSize = isCheckingFileSize
                }
            case .isCheckingImageSize:
                if let value = currentValue, let isCheckingImageSize = Bool(value) {
                    self.isCheckingImageSize = isCheckingImageSize
                }
            case .isCheckingPdfVector:
                if let value = currentValue, let isCheckingPdfVector = Bool(value) {
                    self.isCheckingPdfVector = isCheckingPdfVector
                }
            case .isCheckingSvgVector:
                if let value = currentValue, let isCheckingSvgVector = Bool(value) {
                    self.isCheckingSvgVector = isCheckingSvgVector
                }
            case .isCheckingScaleSize:
                if let value = currentValue, let isCheckingScaleSize = Bool(value) {
                    self.isCheckingScaleSize = isCheckingScaleSize
                }
            case .isCheckingDuplicatedByName:
                if let value = currentValue, let isCheckingDuplicatedByName = Bool(value) {
                    self.isCheckingDuplicatedByName = isCheckingDuplicatedByName
                }
            case .isCheckingDuplicatedByContent:
                if let value = currentValue, let isCheckingDuplicatedByContent = Bool(value) {
                    self.isCheckingDuplicatedByContent = isCheckingDuplicatedByContent
                }
            case .targetPlatforms:
                if let value = currentValue, value.isEmpty == false {
                    if let targetPlatform = Key.TargetPlatform(rawValue: value) {
                        switch targetPlatform {
                        case .iOS:
                            self.targetPlatforms.append(.iOS)
                        case .iPadOS:
                            self.targetPlatforms.append(.iPadOS)
                        case .macOS:
                            self.targetPlatforms.append(.macOS)
                        case .tvOS:
                            self.targetPlatforms.append(.tvOS)
                        case .visionOS:
                            self.targetPlatforms.append(.visionOS)
                        case .watchOS:
                            self.targetPlatforms.append(.watchOS)
                        }
                    }
                } else if isStartKey {
                    self.targetPlatforms = []
                }
            }
            isStartKey = false
        }
        print("\(self)")
    }

    private struct Object {
        let name: String
        let value: String
    }

    private static let regexObject = try! NSRegularExpression(pattern: #"^([A-z0-9]+?)\s*:"#, options: [.caseInsensitive])

    private static func getObject(line: String) -> Object? {
        let results = regexObject.matches(in: line, range: NSRange(line.startIndex..., in: line))
        if let result = results.first {
            let name = String(line[Range(result.range, in: line)!]).dropLast().trimmingCharacters(in: .whitespaces)
            let value = line.suffix(from: Range(result.range, in: line)!.upperBound).trimmingCharacters(in: .whitespaces)
            return Object(name: name, value: value)
        }
        return nil
    }

    private static func getArrayValue(line: String) -> String? {
        guard line.first == "-" else {
            return nil
        }
        return line.dropFirst().trimmingCharacters(in: .whitespaces)
    }

    private static func getArrayObject(line: String) -> Object? {
        guard let value = getArrayValue(line: line) else {
            return nil
        }
        return getObject(line: value)
    }
}
