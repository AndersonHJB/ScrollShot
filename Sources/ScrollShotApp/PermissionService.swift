import ApplicationServices
import CoreGraphics
import Foundation

enum PermissionService {
    static var hasScreenRecordingPermission: Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true
    }

    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    static func requestScreenRecordingPermission() {
        if #available(macOS 10.15, *) {
            _ = CGRequestScreenCaptureAccess()
        }
    }

    static func requestAccessibilityPermission() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
