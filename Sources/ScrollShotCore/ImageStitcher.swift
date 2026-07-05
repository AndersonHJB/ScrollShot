import AppKit
import CoreGraphics
import Foundation

public struct StitchResult {
    public let image: CGImage
    public let overlapPixels: Int
    public let appendedPixels: Int
    public let score: Double
}

public final class ImageStitcher {
    public init() {}

    public func stitch(base: CGImage, next: CGImage, minimumAppendPixels: Int) throws -> StitchResult {
        guard base.width == next.width else {
            return StitchResult(
                image: compose(base: base, next: next, overlapPixels: 0),
                overlapPixels: 0,
                appendedPixels: next.height,
                score: .infinity
            )
        }

        let match = OverlapMatcher.findOverlap(previous: base, next: next, minimumAppendPixels: minimumAppendPixels)
        let output = compose(base: base, next: next, overlapPixels: match.overlapPixels)
        return StitchResult(
            image: output,
            overlapPixels: match.overlapPixels,
            appendedPixels: max(0, next.height - match.overlapPixels),
            score: match.score
        )
    }

    private func compose(base: CGImage, next: CGImage, overlapPixels: Int) -> CGImage {
        let width = max(base.width, next.width)
        let appendHeight = max(1, next.height - overlapPixels)
        let outputHeight = base.height + appendHeight

        guard let context = CGContext(
            data: nil,
            width: width,
            height: outputHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: base.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return base
        }

        context.interpolationQuality = .none
        context.translateBy(x: 0, y: CGFloat(outputHeight))
        context.scaleBy(x: 1, y: -1)
        context.draw(base, in: CGRect(x: 0, y: 0, width: base.width, height: base.height))

        let cropRect = CGRect(x: 0, y: overlapPixels, width: next.width, height: appendHeight)
        if let tail = next.cropping(to: cropRect) {
            context.draw(tail, in: CGRect(x: 0, y: base.height, width: tail.width, height: tail.height))
        } else {
            context.draw(next, in: CGRect(x: 0, y: base.height, width: next.width, height: next.height))
        }

        return context.makeImage() ?? base
    }
}
