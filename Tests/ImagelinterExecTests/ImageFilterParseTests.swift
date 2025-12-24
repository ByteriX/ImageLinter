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

    @Test
    func complex() throws {
        let pattern = "vector, >100kpx , <10Mb)"
        let filter = try #require(ImageFilter(pattern))
        #expect(filter.andConditions.count == 3)
        let orCondition1 = try #require(filter.andConditions[0] as? ImageFilter.OrCondition)
        let typeCondition = try #require(orCondition1.orConditions.first as? ImageFilter.ImageTypeCondition)
        #expect(typeCondition.types.count == 1)
        #expect(typeCondition.types.contains(.vector) == true)
        let orCondition2 = try #require(filter.andConditions[1] as? ImageFilter.OrCondition)
        let sizeCondition1 = try #require(orCondition2.orConditions.first as? ImageFilter.SizeCondition)
        #expect(sizeCondition1.size[0].comparison == ImageFilter.Comparison.greater)
        #expect(sizeCondition1.size[0].value == 100_000)
        #expect(sizeCondition1.size[0].messure == .pixels)
        let orCondition3 = try #require(filter.andConditions[2] as? ImageFilter.OrCondition)
        let sizeCondition2 = try #require(orCondition3.orConditions.first as? ImageFilter.SizeCondition)
        #expect(sizeCondition2.size[0].comparison == ImageFilter.Comparison.less)
        #expect(sizeCondition2.size[0].value == 10 * 1024 * 1024)
        #expect(sizeCondition2.size[0].messure == .bytes)
    }

}
