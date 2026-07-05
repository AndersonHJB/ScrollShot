import AppKit
import CoreGraphics
import Foundation
import ScrollShotCore

final class ScreenCaptureService {
    func capture(rect: CGRect) throws -> CGImage {
        guard let screen = NSScreen.screen(containing: rect) else {
            throw CaptureError.noDisplayForSelection
        }
        guard let displayID = screen.displayID, let displayImage = CGDisplayCreateImage(displayID) else {
            throw CaptureError.captureFailed
        }

        let cropRect = screen.pixelCropRect(forAppKitRect: rect, image: displayImage)
        guard cropRect.width > 0, cropRect.height > 0, let image = displayImage.cropping(to: cropRect) else {
            throw CaptureError.cropFailed
        }
        return image
    }
}

private extension NSScreen {
    static func screen(containing rect: CGRect) -> NSScreen? {
        NSScreen.screens
            .map { screen in (screen, screen.frame.intersection(rect).area) }
            .filter { $0.1 > 0 }
            .max { $0.1 < $1.1 }?
            .0
    }

    var displayID: CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value
    }

    func pixelCropRect(forAppKitRect rect: CGRect, image: CGImage) -> CGRect {
        let clipped = frame.intersection(rect)
        let scaleX = CGFloat(image.width) / max(1, frame.width)
        let scaleY = CGFloat(image.height) / max(1, frame.height)
        let x = (clipped.minX - frame.minX) * scaleX
        let y = (frame.maxY - clipped.maxY) * scaleY
        let width = clipped.width * scaleX
        let height = clipped.height * scaleY
        return CGRect(x: x, y: y, width: width, height: height).integral
    }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull, !isInfinite else { return 0 }
        return max(0, width) * max(0, height)
    }
}
