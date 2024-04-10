# ImageLinter

Check image files and resources for Swift

## Script allows

 1. Checking size of vector(PDF) and rastor(PNG/JPEG) files
 2. Catch raster from PDF
 3. Checking unused image files
 4. Search undefined images
 5. Comparing scaled images size
 6. Checking duplicate images by name
 7. Checking duplicate images by content (but identical)
 8. Search empty and broken asset images
 9. Analysis scales of images with dependency on platforms target

![](Screens/1.png)

## Accessibility

1. Possible analyse the sources (swift, Objective-C files) and resources (Storyboard, xib files)
2. Support Assets and files with @Xx notation
3. vector/rastor diffenition and you can limit use formats by PNG, JPG, PDF, SVG, etc formats
4. Support any use notation: SwiftUI, UIKit, SwiftGen, and custom Regex
5. You can ignore any images
6. Any settings for generation errors or warnings

## Install

From 2.0 version we support SPM plugin.

### Swift Package Manager (SPM)

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. `Imagelinter` supports its use on supported platforms as plugin tool. 

Once you have your Swift package set up, adding `Imagelinter` as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`. Then you need call from your target plugin like this:

```swift

    dependencies: [
        .Package(url: "https://github.com/ByteriX/Imagelinter.git", majorVersion: 2)
    ],
    targets: [
        .target(
            name: "YourTarget",
            plugins: [
                .plugin(name: "ImagelinterPlugin", package: "Imagelinter"),
            ]
        )
    ]
    
```

### Old 1.7 version instalation

1. Just copy ImageLinter.swift to project.
2. Exclude from "Build Phases" -> "Compile Sources"
3. Add to "Build Phases" run script: 
```bash
${SRCROOT}/ImageLinter.swift -imagesPath "/YouProject/Resources/Images" -sourcePath "/YouProject/Source"
```
![](Screens/2.png)

## Setup:

```yaml
isEnabled: true
relativeImagesPath: /Sources/Images/Resources
relativeSourcePath: /Sources/Images
usingTypes:
  - case: uiKit
  - case: swiftUI
  - case: swiftGen
    enumName: Asset
  - case: custom
    pattern: "(.*)".image
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
maxVectorFileSize: 10000
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
```

## Example

You can review ![Examples project](Examples)
