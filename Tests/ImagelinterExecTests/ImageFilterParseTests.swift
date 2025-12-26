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

    struct StaticSizeTest: TestTrait {
        let pattern: String
        let value: Int64
        let messure: ImageFilter.Messure
    }
    @Test(arguments: [
          StaticSizeTest(pattern: " = 10px", value: Int64(10), messure: .pixels),
          StaticSizeTest(pattern: "=20kpx", value: Int64(20_000), messure: .pixels),
          StaticSizeTest(pattern: "=0.3kpx", value: Int64(300), messure: .pixels),
          StaticSizeTest(pattern: "=0.1Mpx", value: Int64(100_000), messure: .pixels),
          StaticSizeTest(pattern: "=2000mpx", value: Int64(2_000_000_000), messure: .pixels),
          StaticSizeTest(pattern: "= 1b", value: Int64(1), messure: .bytes),
          StaticSizeTest(pattern: "= 20kb", value: Int64(20 * 1024), messure: .bytes),
          StaticSizeTest(pattern: "= 0.5Kb", value: Int64(0.5 * 1024), messure: .bytes),
          StaticSizeTest(pattern: "=100Mb", value: Int64(100 * 1024 * 1024), messure: .bytes),
          StaticSizeTest(pattern: "=0.001Mb", value: Int64(0.001 * 1024 * 1024), messure: .bytes)
    ])
    func size(param: StaticSizeTest) throws {
        let filter = try #require(ImageFilter(param.pattern))
        #expect(filter.andConditions.count == 1)
        let orCondition = try #require(filter.andConditions.first as? ImageFilter.OrCondition)
        let sizeCondition = try #require(orCondition.orConditions.first as? ImageFilter.SizeCondition)
        #expect(sizeCondition.size[0].comparison == ImageFilter.Comparison.equal)
        #expect(sizeCondition.size[0].value == param.value)
        #expect(sizeCondition.size[0].messure == param.messure)
    }

    @Test(arguments: zip(
        ["vector, >100kpx , <10Mb",
         ">100kpx , <10Mb, vector",
         ">100kpx , vector, <10Mb",
         "vector, <10Mb, >100kpx"
        ],
        [[0, 1, 2],
         [2, 0, 1],
         [1, 0, 2],
         [0, 2, 1]
        ]
    ))
    func complex(pattern: String, order: [Int]) throws {
        let filter = try #require(ImageFilter(pattern))
        #expect(filter.andConditions.count == 3)
        let orCondition1 = try #require(filter.andConditions[order[0]] as? ImageFilter.OrCondition)
        let typeCondition = try #require(orCondition1.orConditions.first as? ImageFilter.ImageTypeCondition)
        #expect(typeCondition.types.count == 1)
        #expect(typeCondition.types.contains(.vector) == true)
        let orCondition2 = try #require(filter.andConditions[order[1]] as? ImageFilter.OrCondition)
        let sizeCondition1 = try #require(orCondition2.orConditions.first as? ImageFilter.SizeCondition)
        #expect(sizeCondition1.size[0].comparison == ImageFilter.Comparison.greater)
        #expect(sizeCondition1.size[0].value == 100_000)
        #expect(sizeCondition1.size[0].messure == .pixels)
        let orCondition3 = try #require(filter.andConditions[order[2]] as? ImageFilter.OrCondition)
        let sizeCondition2 = try #require(orCondition3.orConditions.first as? ImageFilter.SizeCondition)
        #expect(sizeCondition2.size[0].comparison == ImageFilter.Comparison.less)
        #expect(sizeCondition2.size[0].value == 10 * 1024 * 1024)
        #expect(sizeCondition2.size[0].messure == .bytes)
    }

}
