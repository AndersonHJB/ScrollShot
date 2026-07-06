# ScrollShot

ScrollShot 是一个原生 macOS 长截图工具，支持框选屏幕区域、自动滚动、连续截图和自动拼接，适合网页、文档、聊天记录等可滚动内容。

## 功能

- 框选任意显示器上的单屏幕滚动区域
- 支持用户在软件中自定义全局快捷键，可在其他软件、全屏 Space 或外接屏目标上直接触发
- 自动隐藏自身，避免截到应用窗口
- 发送滚轮事件并连续捕获同一区域
- 基于重叠内容自动拼接长图
- 导出 PNG 到 `~/Pictures/ScrollShot`
- 内置屏幕录制和辅助功能权限检查

## 系统要求

- macOS 13 或更高版本
- 首次使用需要在系统设置中授予：
  - 屏幕录制
  - 辅助功能

## 本地开发

```sh
swift build
swift test
swift run ScrollShot
```

## 打包

```sh
Scripts/build_release.sh
```

产物会生成到 `dist/`：

- `ScrollShot-<版本号>.dmg`
- `ScrollShot-<版本号>.zip`
- `ScrollShot-<版本号>-checksums.txt`

打开 `.dmg` 后，将 `ScrollShot.app` 拖拽到 `Applications` 即可安装。

当前脚本会在没有 Developer ID 证书时使用 ad-hoc 签名。要发布给更多用户，建议配置 Apple Developer ID 证书并执行公证流程，见 `Scripts/sign_and_notarize.sh`。

## 使用方式

1. 打开要截图的网页、文档或聊天窗口。
2. 按 `⌃⌥⌘S` 开始长截图。已有选区时会直接开始；没有选区时会先框选，松开鼠标后自动开始。
3. 应用会隐藏自身，自动滚动并拼接。
4. 完成后会显示导出文件位置。

也可以在 ScrollShot 主窗口中手动点击“选择区域”和“开始长截图”。默认全局快捷键包括：

- `⌃⌥⌘S`：开始长截图
- `⌃⌥⌘R`：重新框选区域
- `⌃⌥⌘X`：停止当前截图或取消框选

这些快捷键可以在软件的“全局快捷键”区域中直接调整，修改后会立即生效。

如果目标内容滚动方向相反，打开“反向滚动”。如果拼接断层，降低“滚动像素”或增加“等待时间”。
