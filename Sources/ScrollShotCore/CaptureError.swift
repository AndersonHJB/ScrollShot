import Foundation

public enum CaptureError: LocalizedError {
    case noDisplayForSelection
    case screenshotPermissionMissing
    case accessibilityPermissionMissing
    case captureFailed
    case cropFailed
    case writeFailed(URL)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .noDisplayForSelection:
            return "没有找到选区所在的屏幕。"
        case .screenshotPermissionMissing:
            return "缺少屏幕录制权限。请在系统设置中允许 ScrollShot 录制屏幕。"
        case .accessibilityPermissionMissing:
            return "缺少辅助功能权限。请在系统设置中允许 ScrollShot 控制电脑。"
        case .captureFailed:
            return "屏幕截图失败。"
        case .cropFailed:
            return "裁剪选区失败。"
        case .writeFailed(let url):
            return "写入文件失败：\(url.path)"
        case .cancelled:
            return "截图已取消。"
        }
    }
}
