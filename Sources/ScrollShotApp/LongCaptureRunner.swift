import AppKit
import Foundation
import ScrollShotCore

struct CaptureProgress {
    let fraction: Double
    let text: String
    let message: String
}

struct LongCaptureRunner {
    let settings: CaptureSettings
    let selectionRect: CGRect
    let outputURL: URL

    func run(
        isCancelled: @escaping () async -> Bool,
        progress: @escaping (CaptureProgress) async -> Void
    ) async throws -> URL {
        if await isCancelled() { throw CaptureError.cancelled }
        guard PermissionService.hasScreenRecordingPermission else { throw CaptureError.screenshotPermissionMissing }
        guard PermissionService.hasAccessibilityPermission else { throw CaptureError.accessibilityPermissionMissing }

        let captureService = ScreenCaptureService()
        let scrollService = ScrollService()
        let stitcher = ImageStitcher()

        var duplicateFrames = 0
        var stitched = try captureService.capture(rect: selectionRect)
        var lastFrame = stitched

        await progress(CaptureProgress(
            fraction: 1.0 / Double(settings.maxFrames),
            text: "1 / \(settings.maxFrames)",
            message: "已捕获第 1 帧：\(stitched.width)x\(stitched.height)"
        ))

        for frameIndex in 2...settings.maxFrames {
            if await isCancelled() { throw CaptureError.cancelled }

            scrollService.scroll(selectionRect: selectionRect, pixels: settings.scrollPixels, reverse: settings.reverseScroll)
            try await Task.sleep(nanoseconds: UInt64(settings.delayMilliseconds) * 1_000_000)

            let next = try captureService.capture(rect: selectionRect)
            let result = try stitcher.stitch(base: stitched, next: next, minimumAppendPixels: settings.minimumAppendPixels)
            stitched = result.image

            if result.appendedPixels <= settings.minimumAppendPixels {
                duplicateFrames += 1
            } else {
                duplicateFrames = 0
            }

            await progress(CaptureProgress(
                fraction: Double(frameIndex) / Double(settings.maxFrames),
                text: "\(frameIndex) / \(settings.maxFrames)",
                message: "第 \(frameIndex) 帧，重叠 \(result.overlapPixels) px，追加 \(result.appendedPixels) px，匹配分数 \(String(format: "%.1f", result.score))"
            ))

            lastFrame = next
            if duplicateFrames >= settings.stopAfterDuplicateFrames {
                await progress(CaptureProgress(
                    fraction: Double(frameIndex) / Double(settings.maxFrames),
                    text: "\(frameIndex) / \(settings.maxFrames)",
                    message: "检测到连续重复内容，提前结束。"
                ))
                break
            }
            _ = lastFrame
        }

        try PNGWriter.write(stitched, to: outputURL)
        return outputURL
    }
}
