# ScrollShot

ScrollShot 是一个原生 macOS 长截图工具，支持框选屏幕区域、自动滚动、连续截图和自动拼接，适合网页、文档、聊天记录等可滚动内容。

## 功能

- 框选任意单屏幕区域
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
Scripts/build_release.sh 0.1.0
```

产物会生成到 `dist/`：

- `ScrollShot-0.1.0.dmg`
- `ScrollShot-0.1.0.zip`
- `ScrollShot-0.1.0-checksums.txt`

当前脚本会在没有 Developer ID 证书时使用 ad-hoc 签名。要发布给更多用户，建议配置 Apple Developer ID 证书并执行公证流程，见 `Scripts/sign_and_notarize.sh`。

## 使用方式

1. 打开要截图的网页、文档或聊天窗口。
2. 在 ScrollShot 中点击“选择区域”，框选可滚动内容区域。
3. 点击“开始长截图”。
4. 应用会隐藏自身，自动滚动并拼接。
5. 完成后会显示导出文件位置。

如果目标内容滚动方向相反，打开“反向滚动”。如果拼接断层，降低“滚动像素”或增加“等待时间”。
