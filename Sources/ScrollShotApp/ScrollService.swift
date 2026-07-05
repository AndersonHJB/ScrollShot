import AppKit
import CoreGraphics
import Foundation

final class ScrollService {
    func scroll(selectionRect: CGRect, pixels: Int, reverse: Bool) {
        guard let screen = NSScreen.screen(containing: selectionRect) else { return }
        let appKitPoint = CGPoint(x: selectionRect.midX, y: selectionRect.midY)
        let quartzPoint = screen.quartzPoint(fromAppKitPoint: appKitPoint)
        CGWarpMouseCursorPosition(quartzPoint)

        let delta = reverse ? pixels : -pixels
        let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: Int32(delta),
            wheel2: 0,
            wheel3: 0
        )
        event?.location = quartzPoint
        event?.post(tap: .cghidEventTap)
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

    func quartzPoint(fromAppKitPoint point: CGPoint) -> CGPoint {
        guard let displayID else { return point }
        let displayBounds = CGDisplayBounds(displayID)
        let localX = point.x - frame.minX
        let localYFromTop = frame.maxY - point.y
        return CGPoint(
            x: displayBounds.minX + localX,
            y: displayBounds.minY + localYFromTop
        )
    }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull, !isInfinite else { return 0 }
        return max(0, width) * max(0, height)
    }
}
