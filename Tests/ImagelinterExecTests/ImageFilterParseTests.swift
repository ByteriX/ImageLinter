//
//  ImageFilterParseTests.swift
//  Imagelinter
//
//  Created by Sergey Balalaev on 24.12.2025.
//

import Testing
import ImagelinterExec
import Foundation

@Suite("Image filter parser tests")
struct ImageFilterParseTests {

    @Test(arguments: zip(
        [">10Mpx", "=>10Kpx", ">=100000Mpx",
         "=10Mpx", "==10Kpx", "==100000Mpx",
         "<10Mpx", "=<10Kpx", "<=100000Mpx"],
        [ImageFilter.Comparison.greater, ImageFilter.Comparison.greater, ImageFilter.Comparison.greater,
         ImageFilter.Comparison.equal, ImageFilter.Comparison.equal, ImageFilter.Comparison.equal,
         ImageFilter.Comparison.less, ImageFilter.Comparison.less, ImageFilter.Comparison.less,
        ]
    ))
    func condition(pattern: String, comparison: ImageFilter.Comparison) throws {
        let filter = try #require(ImageFilter(pattern))
        #expect(filter.andConditions.count == 1)
        let orCondition = try #require(filter.andConditions.first as? ImageFilter.OrCondition)
        let sizeCondition = try #require(orCondition.orConditions.first as? ImageFilter.SizeCondition)
        #expect(sizeCondition.size.count == 1)
        #expect(sizeCondition.size[0].comparison == comparison)
    }

    
}
