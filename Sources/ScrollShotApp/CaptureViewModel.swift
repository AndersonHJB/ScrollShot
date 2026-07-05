import AppKit
import Foundation
import ScrollShotCore

@MainActor
final class CaptureViewModel: ObservableObject {
    @Published var hasScreenRecordingPermission = PermissionService.hasScreenRecordingPermission
    @Published var hasAccessibilityPermission = PermissionService.hasAccessibilityPermission
    @Published var selectionRect: CGRect?
    @Published var maxFrames = 24
    @Published var scrollPixels = 720
    @Published var delayMilliseconds = 550
    @Published var reverseScroll = false
    @Published var minimumAppendPixels = 80
    @Published var isCapturing = false
    @Published var progress = 0.0
    @Published var progressText = ""
    @Published var logs: [String] = ["准备就绪。"]
    @Published var outputURL: URL?

    private let selector = RegionSelectionController()
    private var cancelRequested = false

    var canStartCapture: Bool {
        selectionRect != nil && !isCapturing && hasScreenRecordingPermission && hasAccessibilityPermission
    }

    var regionDescription: String {
        guard let rect = selectionRect else { return "尚未选择区域" }
        return "x:\(Int(rect.minX)) y:\(Int(rect.minY)) w:\(Int(rect.width)) h:\(Int(rect.height))"
    }

    func refreshPermissions() {
        hasScreenRecordingPermission = PermissionService.hasScreenRecordingPermission
        hasAccessibilityPermission = PermissionService.hasAccessibilityPermission
    }

    func requestScreenRecordingPermission() {
        PermissionService.requestScreenRecordingPermission()
        refreshPermissions()
    }

    func requestAccessibilityPermission() {
        PermissionService.requestAccessibilityPermission()
        refreshPermissions()
    }

    func selectRegion() {
        appendLog("进入框选模式。")
        selector.selectRegion { [weak self] rect in
            Task { @MainActor in
                guard let self else { return }
                if let rect, rect.width >= 40, rect.height >= 40 {
                    self.selectionRect = rect
                    self.appendLog("已选择区域：\(self.regionDescription)")
                } else {
                    self.appendLog("已取消选区。")
                }
            }
        }
    }

    func startCapture() {
        guard let rect = selectionRect else { return }
        refreshPermissions()
        guard hasScreenRecordingPermission else {
            appendLog("缺少屏幕录制权限。")
            return
        }
        guard hasAccessibilityPermission else {
            appendLog("缺少辅助功能权限。")
            return
        }

        let settings = CaptureSettings(
            maxFrames: maxFrames,
            scrollPixels: scrollPixels,
            delayMilliseconds: delayMilliseconds,
            reverseScroll: reverseScroll,
            minimumAppendPixels: minimumAppendPixels
        )
        let output = OutputPathFactory.nextPNGURL()
        let runner = LongCaptureRunner(settings: settings, selectionRect: rect, outputURL: output)

        isCapturing = true
        cancelRequested = false
        progress = 0
        progressText = "0 / \(settings.maxFrames)"
        outputURL = nil
        appendLog("3 秒后开始，请把鼠标保持在目标滚动区域。")

        NSApp.hide(nil)

        Task {
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                let result = try await runner.run(
                    isCancelled: { [weak self] in
                        await MainActor.run { self?.cancelRequested == true }
                    },
                    progress: { [weak self] update in
                        await MainActor.run {
                            self?.progress = update.fraction
                            self?.progressText = update.text
                            self?.appendLog(update.message)
                        }
                    }
                )
                await MainActor.run {
                    self.outputURL = result
                    self.appendLog("完成：\(result.path)")
                    self.finishCapture()
                }
            } catch {
                await MainActor.run {
                    self.appendLog("失败：\(error.localizedDescription)")
                    self.finishCapture()
                }
            }
        }
    }

    func cancelCapture() {
        cancelRequested = true
        appendLog("正在停止。")
    }

    func openOutputFolder() {
        let folder = OutputPathFactory.outputDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folder)
    }

    private func finishCapture() {
        isCapturing = false
        progress = 1
        progressText = ""
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        refreshPermissions()
    }

    private func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        logs.append("[\(formatter.string(from: Date()))] \(message)")
        if logs.count > 160 {
            logs.removeFirst(logs.count - 160)
        }
    }
}
