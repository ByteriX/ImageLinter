//
//  Settings.swift
//  
//
//  Created by Sergey Balalaev on 02.04.2024.
//

import Foundation

struct Settings {
    
    /// For enable or disable this script
    let isEnabled = true

    /// Path to folder with images files. For example "/YouProject/Resources/Images"
    let relativeImagesPath = ""//UserDefaults.standard.string(forKey: "imagesPath")!

    /// Path of the source folder which will used in searching for localization keys you actually use in your project. For Example "/YouProject/Source"
    let relativeSourcePath = ""//UserDefaults.standard.string(forKey: "sourcePath")!

    /// Using localizations type from code. If you use custom you need define regex pattern
    enum UsingType {
        case swiftUI
        case uiKit
        case swiftGen(enumName: String = "Asset")
        case custom(pattern: String)
    }

    /// yuo can use many types
    let usingTypes: [UsingType] = [
        .swiftGen(),
        .swiftUI,
        .uiKit
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

    let sourcesExtensions = ["swift", "mm", "m"]
    let resourcesExtensions = ["storyboard", "xib"]

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

    init() { }

}


