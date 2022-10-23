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

![](Screens/1.png)

## Accessibility

1. Support Assets and files with @Xx notation
2. vector/rastor diffenition and you can limit use formats by PNG, JPG, PDF formats
3. Support any use notation: SwiftUI, UIKit, SwiftGen, and custom Regex
4. You can ignore any images
5. Any settings for generation errors or warnings

## Install

1. Just copy ImageLinter.swift to project.
2. Exclude from "Build Phases" -> "Compile Sources"
3. Add to "Build Phases" run script: 
```bash
${SRCROOT}/ImageLinter.swift
```
![](Screens/2.png)

## Setup:

```swift
/// Path to folder with images files. For example "/YouProject/Resources/Images"
let relativeImagesPath = "/."

/// Path of the source folder which will used in searching for localization keys you actually use in your project. For Example "/YouProject/Source"
let relativeSourcePath = "/."

/// yuo can use many types
let usingTypes: [UsingType] = [
    .swiftUI, .uiKit
]

/**
 If you want to exclude unused image from checking, you can define they this

 Example:
  let ignoredUnusedImages = [
     "ApplicationPoster"
  ]
 */
let ignoredUnusedImages: Set<String> = [
	"AppIcon"
]
let ignoredUndefinedImages: Set<String> = [
	"ReadMe.PDF"
]

let isThrowingErrorForUntranslated = true
let isThrowingErrorForUnused = true
let isClearWhitespasesInLocalizableFiles = false
let isOnlyOneLanguage = false
/// Cleaning localizable files. Will remove comments, empty lines and order your keys by alphabetical.
let isCleaningFiles = false
```

## Example

You can review ![Example project](Example)
