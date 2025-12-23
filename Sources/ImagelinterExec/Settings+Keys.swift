//
//  Settings+Keys.swift
//  Imagelinter
//
//  Created by Sergey Balalaev on 23.12.2025.
//

extension Settings {
    enum Key: String {
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

            func convert(message: String?, filter: ImageFilter?) -> Settings.CheckingNameType {
                if let message {
                    switch self {
                    case .firstUpperCase: return .firstUpperCase(message: message, filter: filter)
                        case .camelCase: return .camelCase(message: message, filter: filter)
                        case .sneak_case: return .sneak_case(message: message, filter: filter)
                        case .kebab_case: return .kebab_case(message: message, filter: filter)
                        case .custom: return .custom(pattern: "", message: message, filter: filter)
                    }
                } else {
                    switch self {
                        case .firstUpperCase: return .firstUpperCase(filter: filter)
                        case .camelCase: return .camelCase(filter: filter)
                        case .sneak_case: return .sneak_case(filter: filter)
                        case .kebab_case: return .kebab_case(filter: filter)
                        case .custom: return .custom(pattern: "", filter: filter)
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
}
