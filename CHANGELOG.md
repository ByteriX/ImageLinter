 
# Changelog

Any significant changes made to this project will be documented in this file.

## [2.1.1] - 2024-05-24

#### Fixed

- Examples for the SPM plugin using and the Swift Script using.

## [2.1.0] - 2024-05-24

#### Added

- Updating script version `ImageLinter.swift` from release script.
- Actualization both examples for using with a Plugin and a Script.

## [2.0.3] - 2024-04-23

#### Added

- Supporting Settings with more yaml/yml extension from Root Library/target with inherited. Priority: target/root, yaml/yml.
- Documentation of Settings file format.

## [2.0.2] - 2024-04-21

#### Fixed

- SwiftGen type options with using .name property.

#### Added

- To Custom type `isSwiftGen` attribute.

## [2.0.1] - 2024-04-18

#### Fixed

- Standart both SwiftGen image using.
- #10 SwiftGen variation with name contains '-' and '_' symbols.

## [2.0.0] - 2024-04-10

#### Added

- Supporting SPM plugin.
- Settings from YAML.
- Changelog.

#### Fixed

- Documentation with intallation and setup settings sections.

## [1.7.0] - 2023-07-14

#### Added

- #3 added checking for platform target

## [1.6.1] - 2023-07-13

#### Fixed

- Readme: ImageLinter call with image and source path from command line
- Example: new case with not found image.
- #8 issue: duplicated errors.

## [1.6.0] - 2023-07-10

#### Added

- Image and source pathes from command line getting

## [1.5.1] - 2023-07-09

#### Fixed

- Commented error for scaled images.

## [1.5.0] - 2023-07-09

#### Added

- Analyse from sources and resources.
- Properties sourcesExtensions, resourcesExtensions, isCheckingImageSize.

## [1.4.0] - 2022-11-21

#### Added

- Supporting checking of rastor in SVG.

## [1.3.1] - 2022-11-21

#### Fixed

- Supporting SVG format.

## [1.3.0] - 2022-11-21

#### Added

- Descriptions to Readme.
- Seporated maxVectorImageSize and maxRastorImageSize.
- Supporting SVG format.

#### Fixed

- Renamed maxVectorFileSize and maxRastorFileSize from maxPdfSize and maxPngSize

## [1.2.3] - 2022-10-07

#### Added

- Search empty and broken asset images.

## [1.2.2] - 2022-10-06

#### Added

- Image name to error message.

#### Fixed

- Bug with regular expressions.
- Full support SwiftGen.

## [1.2.1] - 2022-10-05

#### Added

- Image file filter by extensions.

#### Fixed

- Supporting folder from Asset.

## [1.2.0] - 2022-10-04

#### Added

- Checking duplication images by content
- More Examples error images.
- UsingType settings with uiKit value.
- Search undefined images.
- Checking image size.
- ignoredUnusedImages for excude errors.

## [1.1.0] - 2022-09-28

#### Added

- Searching unused images.
- Checking duplication images by name
- UsingType settings with swiftUI, swiftGen and custom pattern of search.

## [1.0.0] - 2022-09-24

#### Added

- Checking file size.
- PDF vector validation.
- Showing error in XCode.
