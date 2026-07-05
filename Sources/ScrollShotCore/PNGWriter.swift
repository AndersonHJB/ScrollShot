import AppKit
import CoreGraphics
import Foundation

public enum PNGWriter {
    public static func write(_ image: CGImage, to url: URL) throws {
        let representation = NSBitmapImageRep(cgImage: image)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw CaptureError.writeFailed(url)
        }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            throw CaptureError.writeFailed(url)
        }
    }
}
