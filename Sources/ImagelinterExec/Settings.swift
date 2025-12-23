//
//  Settings.swift
//  
//
//  Created by Sergey Balalaev on 02.04.2024.
//

import Foundation

public struct Settings {

    /// For enable or disable this script
    public internal(set) var isEnabled = true

    private(set) var dir: String = defaultDir

    /// Multipath  to folders with images you actually use in your project. For Example ["/YouProject/Resources/Images",  "/OtherProject"]
    public internal(set) var relativeImagesPaths: [String] = []

    /// Multipath  of the sources folders which will used in searching for images you actually use in your project. For Example ["/YouProject/Source",  "/OtherProject"]
    public internal(set) var relativeSourcePaths: [String] = []

    /// Using images type from code. If you use custom you need define regex pattern
    public enum UsingType {
        case swiftUI
        case uiKit
        case uiKitLiteral
        case swiftGen(enumName: String = "Asset")
        case custom(pattern: String, isSwiftGen: Bool)
    }

    /// you can use many types of images usage
    public internal(set) var usingTypes: [UsingType] = [
        .swiftGen(),
        .swiftUI,
        .uiKit,
        .uiKitLiteral
    ]

    /// Patterns of checking of the image name with filter
    public enum CheckingNameType {
        case firstUpperCase(message: String = "Name should start with uppercase", filter: ImageFilter?)
        case camelCase(message: String = "Camel case support only", filter: ImageFilter?)
        case sneak_case (message: String = "Sneak case support only", filter: ImageFilter?)
        case kebab_case (message: String = "Kebab case support only", filter: ImageFilter?)
        case custom (pattern: String, message: String = "Custom name checking", filter: ImageFilter?)
    }

    /// you can check image name with a set of patterns
    public internal(set) var checkingNameTypes: [CheckingNameType] = []

    /**
     If you want to exclude unused image from checking, you can define they this

     Example:
      let ignoredUnusedImages = [
         "ApplicationPoster"
      ]
     */
    public internal(set) var ignoredUnusedImages: Set<String> = [ ]
    public internal(set) var ignoredUndefinedImages: Set<String> = [ ]

    public internal(set) var rastorExtensions = Set<String>(["png", "jpg", "jpeg"].map{$0.uppercased()})
    public internal(set) var vectorExtensions = Set<String>(["pdf", "svg"].map{$0.uppercased()})

    public internal(set) var sourcesExtensions = Set<String>(["swift", "mm", "m"].map{$0.uppercased()})
    public internal(set) var resourcesExtensions = Set<String>(["storyboard", "xib"].map{$0.uppercased()})

    // If you wan't show double errors/warnings for all files of an image change this to false
    public internal(set) var isAllFilesErrorShowing = false

    // Maximum size of Vector files
    public internal(set) var maxVectorFileSize: UInt64 = 20_000
    public internal(set) var maxVectorImageSize: CGSize = CGSize(width: 100, height: 100)

    // Maximum size of Rastor files
    public internal(set) var maxRastorFileSize: UInt64 = 200_000
    public internal(set) var maxRastorImageSize: CGSize = CGSize(width: 1000, height: 1000)

    public internal(set) var isCheckingFileSize = true
    public internal(set) var isCheckingImageSize = true
    public internal(set) var isCheckingPdfVector = true
    public internal(set) var isCheckingSvgVector = true
    public internal(set) var isCheckingScaleSize = true
    public internal(set) var isCheckingDuplicatedByName = true
    public internal(set) var isCheckingDuplicatedByContent = true

    /// Your project should compile for one or more platform. This need for detect quality of images.
    public enum TargetPlatform {
        case iOS
        case iPadOS
        case macOS
        case tvOS
        case visionOS
        case watchOS
    }

    /// yuo can use many platforms
    public internal(set) var targetPlatforms: [TargetPlatform] = [.iOS]

    init(){
        load()
    }

    public init(_ string: String) {
        load(from: string)
    }

}

extension Settings {

    private static let extensions = ["yml", "yaml"]
    private static let fileName = "imagelinter"
    private static let defaultDir: String = pathWithSlash(FileManager.default.currentDirectoryPath)

    static func pathWithSlash(_ path: String) -> String {
        var result = path
        if !result.hasSuffix("/") {
            result = result + "/"
        }
        return result
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

    fileprivate mutating func load(dir: String, ext: String) {

        let filePath = (dir as NSString).appendingPathComponent(Self.fileName + "." + ext)
        guard let stringData = try? String(contentsOfFile: filePath) else {
            print("Settings file '\(filePath)' not found")
            return
        }
        self.dir = dir
        print("Parse settings file '\(filePath)':")

        load(from: stringData)
    }
}

extension Settings.UsingType: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.custom(pattern: let lhsPattern, isSwiftGen: let lhsIsSwiftGen), .custom(pattern: let rhsPattern, isSwiftGen: let rhsIsSwiftGen)):
            return (lhsPattern == rhsPattern) && (lhsIsSwiftGen == rhsIsSwiftGen)
        case (.swiftGen(enumName: let lhsEnumName), .swiftGen(enumName: let rhsEnumName)):
            return lhsEnumName == rhsEnumName
        case (.uiKitLiteral, .uiKitLiteral), (.uiKit, .uiKit), (.swiftUI, .swiftUI):
            return true
        default :
            return false
        }
    }
}
