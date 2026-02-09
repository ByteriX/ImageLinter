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
 10. Checking the name of images with convensions or custom patterns apply filters

![](Screens/1.png)

## Accessibility

1. Possible analyse the sources (swift, Objective-C files) and resources (Storyboard, xib files)
2. Support Assets and files with @Xx notation
3. vector/rastor diffenition and you can limit use formats by PNG, JPG, PDF, SVG, etc formats
4. Support any use notation: SwiftUI, UIKit, SwiftGen, and custom Regex
5. You can ignore any images or sources use
6. Any settings for generation errors or warnings with different filters

## Install

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

### Swift script from Build Phases

1. Just copy ImageLinter.swift to project.
2. Exclude from "Build Phases" -> "Compile Sources"
3. Add to "Build Phases" run script: 
```bash
${SRCROOT}/ImageLinter.swift
```
![](Screens/2.png)

## Settings:

You need to add a settings file named `imagelinter.yaml` or/and `imagelinter.yml` to a `target` or/and `the root of the library` `dir` of the package.
imagesPath and sourcePath are calculated from dir of this package. 

Supports more settings files with rewrite properties with priority: first a `target` then `the root` of library dir, first `imagelinter.yaml` then `imagelinter.yml`.
If you want to have a custom path to settings file, you can use `--settingsPath [path to your imagelinter.yaml or imagelinter.yml file]` command line param from script call only on build phase. In the plugin this would be set to target dirrectory all time.

### How to setting up your yaml file

#### `isEnabled` turn on/off working of this plugin/script. Is boolean param with `true` \ `false` value. Default is `true`.
```yaml
isEnabled: true
```


### Example of Settings file format

```yaml
isEnabled: true
relativeImagesPath: /Sources/Images/Resources
relativeImagesPaths:
  - /Module1/res
  - /Module2/res
relativeSourcePath: /Sources/Code
relativeSourcePaths:
  - /Module1/src
  - /Module2/src
usingTypes:
  - case: uiKit
  - case: uiKitLiteral
  - case: swiftUI
  - case: swiftGen
    enumName: Asset
  - case: custom
    pattern: "(.*)".name
    isSwiftGen: true
  - case: custom
    pattern: "(.*)".image
checkingNameTypes:
  - case: camelCase
  - case: firstUpperCase
    message: First case should be uppered
  - case: custom
    pattern: ^[a-zA-Z][a-zA-Z0-9]*_icon$
    message: Camel case without folder and with suffix '_icon'
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
