//
//  SwiftGen.swift
//
//
//  Created by Sergey Balalaev on 18.04.2024.
//

import Foundation

extension String {

    static let snakeSeporators = "-_"

    func lowercasedFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }

    func uppercasedFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}


fileprivate extension Array where Self.Element == String {
    func swiftGenFolders() -> [Self.Element] {
        guard let last = last else {
            return self
        }
        var result: [Self.Element] = dropLast()
        result.append(last.lowercasedFirstLetter())
        return result
    }

    func swiftGenCamel() -> [Self.Element] {
        guard let first = first else {
            return self
        }
        var result: [Self.Element] = dropFirst().map { $0.uppercasedFirstLetter() }
        result.insert(first, at: 0)
        return result
    }
}

extension String {
    func swiftGenCamel() -> String {
        return self
            .trimmingCharacters(in: CharacterSet(charactersIn: Self.snakeSeporators))
            .split(whereSeparator: { char in
                Self.snakeSeporators.contains { $0 == char }
            })
            .map { String($0) }
            .swiftGenCamel()
            .joined(separator: "")
    }
}

extension String {
    func swiftGenKey() -> String {
        return self
            .split(separator: "/")
            .map { String($0).swiftGenCamel() }
            .swiftGenFolders()
            .joined(separator: ".")
    }
}
