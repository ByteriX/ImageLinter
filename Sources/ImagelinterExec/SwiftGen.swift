//
//  File.swift
//  
//
//  Created by Sergey Balalaev on 18.04.2024.
//

import Foundation


fileprivate extension Array where Self.Element == String {
    func swiftGenFolders() -> [Self.Element] {
        guard let last = last else {
            return self
        }
        var result: [Self.Element] = dropLast()
        result.append(last.lowercasedFirstLetter())
        return result
    }
}

extension String {
    func swiftGenKey() -> String {
        return self
            .split(separator: "/")
            .map { String($0) }
            .swiftGenFolders()
            .joined(separator: ".")
    }
}
