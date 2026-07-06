import AppKit
import ScrollShotCore
import SwiftUI

struct ContentView: View {
    @StateObject private var model = CaptureViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            permissionPanel
            regionPanel
            shortcutPanel
            settingsPanel
            actionPanel
            logPanel
        }
        .padding(22)
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .scrollShotGlobalHotKey)) { notification in
            guard let command = notification.userInfo?[GlobalHotKeyCommand.userInfoKey] as? GlobalHotKeyCommand else {
                return
            }
            model.handleGlobalHotKey(command)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshPermissions()
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ScrollShot")
                    .font(.system(size: 30, weight: .semibold))
                Text("框选滚动区域，自动滚动并拼接成长截图。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let outputURL = model.outputURL {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                } label: {
                    Label("显示结果", systemImage: "folder")
                }
            }
        }
    }

    private var permissionPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("权限")
                .font(.headline)
            HStack(spacing: 10) {
                PermissionBadge(
                    title: "屏幕录制",
                    granted: model.hasScreenRecordingPermission
                )
                PermissionBadge(
                    title: "辅助功能",
                    granted: model.hasAccessibilityPermission
                )
                Spacer()
                Button {
                    model.refreshPermissions()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                Button {
                    model.requestScreenRecordingPermission()
                } label: {
                    Label("请求屏幕录制", systemImage: "record.circle")
                }
                Button {
                    model.requestAccessibilityPermission()
                } label: {
                    Label("请求辅助功能", systemImage: "hand.raised")
                }
            }
        }
    }

    private var regionPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选区")
                .font(.headline)
            HStack {
                Text(model.regionDescription)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(model.selectionRect == nil ? .secondary : .primary)
                    .lineLimit(1)
                Spacer()
                Button {
                    model.selectRegion()
                } label: {
                    Label("选择区域", systemImage: "crop")
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }

    private var shortcutPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("全局快捷键")
                .font(.headline)
            VStack(spacing: 8) {
                ForEach(GlobalHotKeyCommand.allCases, id: \.rawValue) { command in
                    ShortcutEditorRow(
                        command: command,
                        hotKey: hotKeyBinding(for: command),
                        reset: {
                            model.resetHotKey(for: command)
                        }
                    )
                }
                HStack {
                    Spacer()
                    Button {
                        model.resetAllHotKeys()
                    } label: {
                        Label("恢复默认", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
    }

    private func hotKeyBinding(for command: GlobalHotKeyCommand) -> Binding<GlobalHotKey> {
        Binding {
            model.hotKey(for: command)
        } set: { hotKey in
            model.setHotKey(hotKey, for: command)
        }
    }

    private var settingsPanel: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
            GridRow {
                Text("最大帧数")
                Stepper(value: $model.maxFrames, in: 2...80) {
                    Text("\(model.maxFrames)")
                        .frame(width: 52, alignment: .leading)
                }
                Text("滚动像素")
                Stepper(value: $model.scrollPixels, in: 120...2400, step: 40) {
                    Text("\(model.scrollPixels)")
                        .frame(width: 72, alignment: .leading)
                }
            }
            GridRow {
                Text("等待时间")
                Stepper(value: $model.delayMilliseconds, in: 150...2000, step: 50) {
                    Text("\(model.delayMilliseconds) ms")
                        .frame(width: 92, alignment: .leading)
                }
                Text("最少追加")
                Stepper(value: $model.minimumAppendPixels, in: 20...600, step: 20) {
                    Text("\(model.minimumAppendPixels) px")
                        .frame(width: 84, alignment: .leading)
                }
            }
            GridRow {
                Toggle("反向滚动", isOn: $model.reverseScroll)
                Text("当目标内容向上滚动时启用")
                    .foregroundStyle(.secondary)
                    .gridCellColumns(3)
            }
        }
    }

    private var actionPanel: some View {
        HStack(spacing: 12) {
            Button {
                model.startCapture()
            } label: {
                Label(model.isCapturing ? "截图中" : "开始长截图", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canStartCapture)
            .keyboardShortcut(.return, modifiers: [.command])

            Button {
                model.cancelCapture()
            } label: {
                Label("停止", systemImage: "stop.circle")
            }
            .disabled(!model.isCapturing)

            if model.isCapturing {
                ProgressView(value: model.progress)
                    .frame(width: 190)
                Text(model.progressText)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.openOutputFolder()
            } label: {
                Label("输出文件夹", systemImage: "folder.badge.gearshape")
            }
        }
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("日志")
                .font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(model.logs.indices, id: \.self) { index in
                        Text(model.logs[index])
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
            }
            .frame(minHeight: 130)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct ShortcutEditorRow: View {
    let command: GlobalHotKeyCommand
    @Binding var hotKey: GlobalHotKey
    let reset: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(command.title)
                .frame(width: 86, alignment: .leading)
            Text(hotKey.displayShortcut)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .frame(width: 92, alignment: .leading)
            ForEach(GlobalHotKey.modifierOptions) { modifier in
                Toggle(modifier.symbol, isOn: modifierBinding(modifier.flag))
                    .toggleStyle(.button)
                    .help(modifier.name)
            }
            Picker("按键", selection: keyBinding) {
                ForEach(GlobalHotKey.keyOptions) { option in
                    Text(option.label).tag(option.keyCode)
                }
            }
            .labelsHidden()
            .frame(width: 72)
            Spacer()
            Button {
                reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .help("恢复默认")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var keyBinding: Binding<UInt32> {
        Binding {
            hotKey.keyCode
        } set: { keyCode in
            hotKey = hotKey.settingKeyCode(keyCode)
        }
    }

    private func modifierBinding(_ modifier: UInt32) -> Binding<Bool> {
        Binding {
            hotKey.hasModifier(modifier)
        } set: { enabled in
            hotKey = hotKey.settingModifier(modifier, enabled: enabled)
        }
    }
}

private struct PermissionBadge: View {
    let title: String
    let granted: Bool

    var body: some View {
        Label(title, systemImage: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .foregroundStyle(granted ? .green : .orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
