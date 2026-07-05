import AppKit
import CoreGraphics
import Foundation

struct OverlapMatch {
    let overlapPixels: Int
    let score: Double
}

enum OverlapMatcher {
    static func findOverlap(previous: CGImage, next: CGImage, minimumAppendPixels: Int) -> OverlapMatch {
        let previousSample = SampledImage(cgImage: previous)
        let nextSample = SampledImage(cgImage: next)

        guard previousSample.width == nextSample.width, previousSample.height > 12, nextSample.height > 12 else {
            return OverlapMatch(overlapPixels: 0, score: .infinity)
        }

        let availableOverlap = max(8, min(previousSample.height, nextSample.height) - 4)
        let minimumAppend = max(4, Int(round(Double(minimumAppendPixels) * previousSample.scaleY)))
        let minOverlap = 8
        let maxOverlap = max(minOverlap, min(availableOverlap, nextSample.height - minimumAppend))
        let step = max(1, maxOverlap / 180)

        var bestOverlap = minOverlap
        var bestScore = Double.infinity

        if minOverlap <= maxOverlap {
            for overlap in stride(from: minOverlap, through: maxOverlap, by: step) {
                let score = meanAbsoluteError(
                    previous: previousSample,
                    next: nextSample,
                    overlapRows: overlap
                )
                if score < bestScore {
                    bestScore = score
                    bestOverlap = overlap
                }
            }
        }

        let overlapPixels = Int(round(Double(bestOverlap) / previousSample.scaleY))
        return OverlapMatch(
            overlapPixels: min(next.height - 1, max(0, overlapPixels)),
            score: bestScore
        )
    }

    private static func meanAbsoluteError(previous: SampledImage, next: SampledImage, overlapRows: Int) -> Double {
        let width = min(previous.width, next.width)
        let previousStart = previous.height - overlapRows
        var total = 0
        var count = 0
        let columnStep = max(1, width / 180)
        let rowStep = max(1, overlapRows / 120)

        for row in stride(from: 0, to: overlapRows, by: rowStep) {
            let previousRow = previousStart + row
            let nextRow = row
            for column in stride(from: 0, to: width, by: columnStep) {
                let lhs = Int(previous.gray[previousRow * previous.width + column])
                let rhs = Int(next.gray[nextRow * next.width + column])
                total += abs(lhs - rhs)
                count += 1
            }
        }

        guard count > 0 else { return .infinity }
        return Double(total) / Double(count)
    }
}

private struct SampledImage {
    let width: Int
    let height: Int
    let scaleY: Double
    let gray: [UInt8]

    init(cgImage: CGImage, targetWidth: Int = 260) {
        let width = max(32, min(targetWidth, cgImage.width))
        let height = max(16, Int(round(Double(cgImage.height) * Double(width) / Double(max(1, cgImage.width)))))
        self.width = width
        self.height = height
        self.scaleY = Double(height) / Double(max(1, cgImage.height))

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { rawBuffer in
            guard let context = CGContext(
                data: rawBuffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return
            }
            context.interpolationQuality = .low
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        var gray = [UInt8](repeating: 0, count: width * height)
        for index in 0..<(width * height) {
            let offset = index * 4
            let red = Int(pixels[offset])
            let green = Int(pixels[offset + 1])
            let blue = Int(pixels[offset + 2])
            gray[index] = UInt8((red * 299 + green * 587 + blue * 114) / 1000)
        }
        self.gray = gray
    }
}
