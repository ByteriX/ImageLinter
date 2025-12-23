//
//  SettingsTests.swift
//  Imagelinter
//
//  Created by Sergey Balalaev on 23.12.2025.
//

import Testing
import ImagelinterExec
import Foundation

struct SettingsTests {


    @Test
    func testSimplePath() {
        let settings = Settings("""
            relativeImagesPaths:
                - /Resources/ForTest
            relativeSourcePath:
                - /Sources/ForTest/
            """)
        #expect(settings.relativeImagesPaths == ["/Resources/ForTest/"])
        #expect(settings.relativeSourcePaths == ["/Sources/ForTest/"])
    }

    @Test
    func testManyPath() {
        let settings = Settings("""
            relativeImagesPaths:
                - 1
                - 2
            relativeSourcePath:
                -3
                -4
            """)
        #expect(settings.relativeImagesPaths == ["1/", "2/"])
        #expect(settings.relativeSourcePaths == ["3/", "4/"])
    }

    @Test
    func testCustomUsingType() throws {
        let settings = Settings("""
            usingTypes:
              - case: custom
                pattern: "(.*)".image
                isSwiftGen: true
            """)
        #expect(settings.usingTypes.count == 1)

        let usingType = try #require(settings.usingTypes.first)
        if case let .custom(pattern: pattern, isSwiftGen: isSwiftGen) = usingType {
            #expect(pattern == "\"(.*)\".image")
            #expect(isSwiftGen == true)
        } else {
            Issue.record("Wrong type: \(usingType)")
        }
    }

    @Test
    func testDefaultUsingType() {
        let settings = Settings("")
        #expect(settings.usingTypes.count == 4)
        #expect(settings.usingTypes[0] == .swiftGen())
        #expect(settings.usingTypes[1] == .swiftUI)
        #expect(settings.usingTypes[2] == .uiKit)
        #expect(settings.usingTypes[3] == .uiKitLiteral)
    }

    @Test
    func testManyUsingType() {
        let settings = Settings("""
                        usingTypes:
                          - case: swiftGen
                            enumName: Asset
                          - case: custom
                            pattern: "(.*)".image
                            isSwiftGen: false
                          - case: custom
                            pattern: "test".image
                            isSwiftGen: true
            """)
        #expect(settings.usingTypes.count == 3)

        let usingType1 = settings.usingTypes[0]
        if case let .swiftGen(enumName: enumName) = usingType1 {
            #expect(enumName == "Asset")
        } else {
            Issue.record("Wrong type: \(usingType1)")
        }

        let usingType2 = settings.usingTypes[1]
        if case let .custom(pattern: pattern, isSwiftGen: isSwiftGen) = usingType2 {
            #expect(pattern == "\"(.*)\".image")
            #expect(isSwiftGen == false)
        } else {
            Issue.record("Wrong type: \(usingType2)")
        }
        let usingType3 = settings.usingTypes[2]
        if case let .custom(pattern: pattern, isSwiftGen: isSwiftGen) = usingType3 {
            #expect(pattern == "\"test\".image")
            #expect(isSwiftGen == true)
        } else {
            Issue.record("Wrong type: \(usingType3)")
        }
    }

    @Test
    func testAllParse() {
        let settings = Settings("""
            isEnabled: true
            relativeImagesPath: /Sources/Images/Resources/Error
            relativeSourcePath: /
            relativeSourcePaths:
              - /Sources1
              - /Sources2
            usingTypes:
              - case: uiKit
              - case: uiKitLiteral
              - case: swiftUI
              - case: swiftGen
                enumName: Asset
              - case: custom
                pattern: "(.*)".image
                isSwiftGen: false
              - case: custom
                pattern: "(.*)".image
                isSwiftGen: true
                - case: custom
                pattern: "(.*)".name
            checkingNameTypes:
              - case: camelCase
                filter: vector, >1kb
              - case: firstUpperCase
                message: First case should be uppered for vector images with 50px and more
                filter: vector, > 0.05Kpx
            ignoredUnusedImages:
              - temp
            ignoredUndefinedImages:
              - temp
            rastorExtensions:
              - png
              - jpg
              - jpeg
            vectorExtensions:
              - pdf
              - svg
            sourcesExtensions:
              - swift
              - mm
            resourcesExtensions:
              - storyboard
              - xib
            isAllFilesErrorShowing: false
            maxVectorFileSize: 30000
            maxVectorImageSize:
              width: 100
              height: 100
            maxRastorFileSize: 300000
            maxRastorImageSize:
              width: 300
              height: 300
            isCheckingFileSize: true
            isCheckingImageSize: true
            isCheckingPdfVector: true
            isCheckingSvgVector: true
            isCheckingScaleSize: true
            isCheckingDuplicatedByName: true
            isCheckingDuplicatedByContent: true
            targetPlatforms:
              - iOS
              - iPadOS
              - macOS
              - tvOS
              - visionOS
              - watchOS
            """)
        #expect(settings.isEnabled == true)
        #expect(settings.relativeSourcePaths == ["/", "/Sources1/", "/Sources2/"])
        #expect(settings.relativeImagesPaths == ["/Sources/Images/Resources/Error/"])

        #expect(settings.isAllFilesErrorShowing == false)
        #expect(settings.maxVectorFileSize == 30000)
        #expect(settings.maxVectorImageSize == CGSize(width: 100, height: 100))
        #expect(settings.maxRastorFileSize == 300000)
        #expect(settings.maxRastorImageSize == CGSize(width: 300, height: 300))
        #expect(settings.isCheckingFileSize == true)
        #expect(settings.isCheckingImageSize == true)
        #expect(settings.isCheckingPdfVector == true)
        #expect(settings.isCheckingSvgVector == true)
        #expect(settings.isCheckingScaleSize == true)
        #expect(settings.isCheckingDuplicatedByName == true)
        #expect(settings.isCheckingDuplicatedByContent == true)
        #expect(settings.targetPlatforms == [.iOS, .iPadOS, .macOS, .tvOS, .visionOS, .watchOS])
    }

}
