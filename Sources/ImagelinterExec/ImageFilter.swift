//
//  ImageFilter.swift
//  Imagelinter
//
//  Created by Sergey Balalaev on 09.12.2025.
//

import Foundation
import AppKit

struct ImageFilter {

    protocol Condition {
        func include(image: ImageInfo) -> Bool
    }

    var andConditions: [Condition] = []

    init? (_ string: String) {
        guard string.isEmpty == false else {
            return nil
        }
        string.components(separatedBy: ",").forEach { conditionString in
            if let orConditions = OrCondition(conditionString) {
                andConditions.append(orConditions)
            }
        }
        if andConditions.isEmpty {
            return nil
        }
    }

    func include(image: ImageInfo) -> Bool {
        var result = true
        andConditions.forEach { condition in
            result = result && condition.include(image: image)
        }
        return result
    }
}

extension ImageFilter {
    struct OrCondition: Condition {
        var orConditions: [Condition] = []

        init? (_ string: String) {
            guard string.isEmpty == false else {
                return nil
            }
            if let imageTypeCondition = ImageTypeCondition(string) {
                orConditions.append(imageTypeCondition)
            }
            if let sizeCondition = SizeCondition(string) {
                orConditions.append(sizeCondition)
            }
            if orConditions.isEmpty {
                return nil
            }
        }

        func include(image: ImageInfo) -> Bool {
            var result: Bool = false
            orConditions.forEach { condition in
                result = result || condition.include(image: image)
            }
            return result
        }
    }
}

extension ImageFilter {
    struct ImageTypeCondition: Condition {

        private static let pattern = try! NSRegularExpression(pattern: #"[\s\/\|\/]*(undefined|rastor|vector|mixed)[\s\/\|\/]*"#, options: [])

        private var types: Set<ImageInfo.ImageType>

        init? (_ string: String) {
            guard string.isEmpty == false else {
                return nil
            }
            var types = Set<ImageInfo.ImageType>()
            Self.pattern.matches(in: string, options: [], range: NSRange(string.startIndex..., in: string)).forEach
            { result in
                guard result.numberOfRanges > 0 else {
                    return
                }
                (1...result.numberOfRanges - 1).map { index in
                    let value = (string as NSString).substring(with: result.range(at: index))
                    if let type = ImageInfo.ImageType(rawValue: value) {
                        types.insert(type)
                    }
                }
            }
            if types.isEmpty {
                return nil
            }
            self.types = types
        }

        func include(image: ImageInfo) -> Bool {
            types.contains(image.type)
        }
    }
}

extension ImageFilter {
    enum Messure {
        case bytes
        case pixels

        init?(string: String) {
            if string == "PX" || string == "px" || string == "Px" {
                self = .pixels
            } else if string == "B" || string == "b" {
                self = .bytes
            } else {
                return nil
            }
        }
    }

    enum Comparison {
        case equal
        case greater
        case less

        init?(string: String) {
            if string == ">" || string == "=>" || string == ">=" {
                self = .greater
            } else if string == "<" || string == "=<" || string == "<=" {
                self = .less
            } else if string == "=" || string == "==" {
                self = .equal
            } else {
                return nil
            }
        }
    }

    struct Size {
        let value: Int64
        let messure: Messure
        let comparison: Comparison

        init?(strings: [String]) {
            guard strings.count == 4 else {
                return nil
            }
            guard let comparison = Comparison(string: strings[0]) else {
                return nil
            }
            guard var rawValue = Double(strings[1]) else {
                return nil
            }
            guard let messure = Messure(string: strings[3]) else {
                return nil
            }
            let scale = strings[2].uppercased()
            if messure == .pixels {
                if scale == "M" {
                    rawValue *= 1000 * 1000
                } else if scale == "K" {
                    rawValue *= 1000
                }
            } else if messure == .bytes {
                if scale == "M" {
                    rawValue *= 1024 * 1024
                } else if scale == "K" {
                    rawValue *= 1024
                }
            }
            self.value = Int64(rawValue)
            self.messure = messure
            self.comparison = comparison
        }

        func include(image: ImageInfo) -> Bool {
            var value: UInt64 = 0

            switch messure {
            case .bytes:
                guard let size = image.fileSizes.first else {
                    return true
                }

                value = size
                for item in image.fileSizes {
                    if value < item {
                        value = item
                    }
                }
            case .pixels:
                guard let size = image.imageSizes.first else {
                    return true
                }

                value = UInt64(size.width)
                for item in image.imageSizes {
                    if value < UInt64(item.height) {
                        value = UInt64(item.height)
                    } else if value < UInt64(item.width) {
                        value = UInt64(item.width)
                    }
                }
            }

            switch comparison {
            case .equal:
                return value == Int64(self.value)
            case .greater:
                return value >= Int64(self.value)
            case .less:
                return value <= Int64(self.value)
            }
        }
    }

    struct SizeCondition: Condition {
        private static let pattern = try! NSRegularExpression(pattern: #"[\s\/\|\/]*(>|=>|>=|<|=<|<=|=|==)\s*([0-9.]*)\s*(M|m|K|k|)(PX|px|Px|b|B)[\s\/\|\/]*"#, options: [])

        private var size: [Size] = []

        init? (_ string: String) {
            guard string.isEmpty == false else {
                return nil
            }
            Self.pattern.matches(in: string, options: [], range: NSRange(string.startIndex..., in: string)).forEach
            { result in
                guard result.numberOfRanges > 0 else {
                    return
                }
                var strings : [String] = []
                (1...result.numberOfRanges - 1).map { index in
                    let value = (string as NSString).substring(with: result.range(at: index))
                    strings.append(value)
                }
                if let size = Size(strings: strings) {
                    self.size.append(size)
                }
            }
            if self.size.isEmpty {
                return nil
            }
        }

        func include(image: ImageInfo) -> Bool {
            var result: Bool = false

            for item in size {
                result = result || item.include(image: image)
            }

            return result
        }
    }
}
