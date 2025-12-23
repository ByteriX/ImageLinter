//
//  Settings+Parse.swift
//  Imagelinter
//
//  Created by Sergey Balalaev on 23.12.2025.
//
import Foundation

extension Settings {

    mutating func load(from stringData: String) {
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
                                while lineIndex < lines.count,
                                      line.hasPrefix("#") == false,
                                      let object = Self.getObject(line: line),
                                      object.name == "pattern" || object.name == "isSwiftGen"
                                {
                                    lineIndex += 1
                                    if object.name == "pattern" {
                                        customPattern = object.value
                                    } else if object.name == "isSwiftGen", let isSwiftGen = Bool(object.value) {
                                        customIsSwiftGen = isSwiftGen
                                    }
                                    if lineIndex < lines.count {
                                        line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                    }
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
                // TODO: # needs refactory with delete CheckingNameRegexPattern
                if let value = currentValue, value.isEmpty == false {
                    if let object = Self.getObject(line: value), object.name == "case" {
                        if let checkingNameType = Key.CheckingNameType(rawValue: object.value) {
                            switch checkingNameType {
                            case .firstUpperCase, .camelCase, .sneak_case, .kebab_case:
                                guard lineIndex < lines.count else {
                                    break
                                }
                                var line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                var customMessage: String?
                                var customFilter: ImageFilter?

                                // TODO: # needs just continue
                                while
                                    lineIndex < lines.count,
                                    line.hasPrefix("#") == false,
                                    let object = Self.getObject(line: line),
                                    object.name == "message" || object.name == "filter"
                                {
                                    lineIndex += 1
                                    if object.name == "message" {
                                        customMessage = object.value
                                    } else if object.name == "filter" {
                                        customFilter = ImageFilter(object.value)
                                    }
                                    if lineIndex < lines.count {
                                        line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                    }
                                }
                                self.checkingNameTypes.append(checkingNameType.convert(message: customMessage, filter: customFilter))
                            case .custom:
                                guard lineIndex < lines.count else {
                                    break
                                }
                                var line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                var customPattern: String?
                                var customMessage: String?
                                var customFilter: ImageFilter?

                                // TODO: # needs just continue
                                while lineIndex < lines.count,
                                      line.hasPrefix("#") == false,
                                      let object = Self.getObject(line: line),
                                      object.name == "pattern" || object.name == "message" || object.name == "filter"
                                {
                                    lineIndex += 1
                                    if object.name == "pattern" {
                                        customPattern = object.value
                                    } else if object.name == "message" {
                                        customMessage = object.value
                                    } else if object.name == "filter" {
                                        customFilter = ImageFilter(object.value)
                                    }
                                    if lineIndex < lines.count {
                                        line = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                                    }
                                }
                                if let customPattern {
                                    if let customMessage, customMessage.isEmpty == false {
                                        self.checkingNameTypes.append(.custom(pattern: customPattern, message: customMessage, filter: customFilter))
                                    } else {
                                        self.checkingNameTypes.append(.custom(pattern: customPattern, filter: customFilter))
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
