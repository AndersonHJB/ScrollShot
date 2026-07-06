import AppKit
import CoreGraphics
import ScrollShotCore
import XCTest

final class ImageStitcherTests: XCTestCase {
    func testStitchAppendsOnlyNonOverlappingBottom() throws {
        let first = try makeStripedImage(width: 160, height: 220, startRow: 0)
        let second = try makeStripedImage(width: 160, height: 220, startRow: 120)

        let result = try ImageStitcher().stitch(base: first, next: second, minimumAppendPixels: 30)

        XCTAssertGreaterThan(result.overlapPixels, 70)
        XCTAssertLessThan(result.overlapPixels, 130)
        XCTAssertGreaterThan(result.appendedPixels, 80)
        XCTAssertLessThan(result.appendedPixels, 150)
        XCTAssertEqual(result.image.width, 160)
        XCTAssertGreaterThan(result.image.height, 300)
    }

    func testStitchPreservesContinuousRows() throws {
        let first = try makeRowNumberImage(width: 80, height: 100, startRow: 0)
        let second = try makeRowNumberImage(width: 80, height: 100, startRow: 60)

        let result = try ImageStitcher().stitch(base: first, next: second, minimumAppendPixels: 20)

        XCTAssertEqual(result.overlapPixels, 40)
        XCTAssertEqual(result.appendedPixels, 60)
        XCTAssertEqual(result.image.height, 160)

        let rows = try redChannelRows(from: result.image, sampleX: 11)
        XCTAssertEqual(rows, Array(0..<160).map(UInt8.init))
    }

    private func makeStripedImage(width: Int, height: Int, startRow: Int) throws -> CGImage {
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            let sourceRow = startRow + y
            let red = UInt8((sourceRow * 37) % 251)
            let green = UInt8((sourceRow * 67) % 241)
            let blue = UInt8((sourceRow * 97) % 239)
            for x in 0..<width {
                let offset = (y * width + x) * 4
                pixels[offset] = UInt8((Int(red) + x) % 255)
                pixels[offset + 1] = green
                pixels[offset + 2] = blue
                pixels[offset + 3] = 255
            }
        }

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cgImage = context.makeImage() else {
            throw XCTSkip("Could not create test image")
        }
        return cgImage
    }

    private func makeRowNumberImage(width: Int, height: Int, startRow: Int) throws -> CGImage {
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            let row = UInt8(startRow + y)
            for x in 0..<width {
                let offset = (y * width + x) * 4
                pixels[offset] = row
                pixels[offset + 1] = UInt8(x)
                pixels[offset + 2] = UInt8(255 - Int(row))
                pixels[offset + 3] = 255
            }
        }

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cgImage = context.makeImage() else {
            throw XCTSkip("Could not create test image")
        }
        return cgImage
    }

    private func redChannelRows(from image: CGImage, sampleX: Int) throws -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw XCTSkip("Could not create test context")
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        return (0..<image.height).map { y in
            pixels[(y * image.width + sampleX) * 4]
        }
    }
}
