# ZCode 远程 (iOS/iPadOS)

> 把 ZCode 桌面端的「手机连接」远程功能封装成 iPhone / iPad App，**保存链接、一键连接**，不用每次到电脑前扫码。
>
> SwiftUI 版的 [ZCode 远程 (Android)](https://github.com/Deep-AI-Evo/zcode-remote-apk) 姊妹项目。

> ⚠️ **第三方非官方版本**：与智谱 / ZCode 官方无任何关系，只是把官方「手机连接」网页封装成本地 App。
>
> 🔒 **权限极少**：仅「相机」（扫码用）+ 系统「照片选择器」（网页上传图片用，PHPicker 免权限）。无定位、无通讯录、无存储、无后台常驻。

## 功能 / Features

- 📱 **一键连接**：保存的远程链接点一下就进，WKWebView 承载官方远程页面
- 📷 **扫码添加**：iOS 16+ DataScanner 实时取景扫码；也支持粘贴链接
- 🎛️ **浮动工具条**：连接页顶部悬浮胶囊（返回 / 刷新 / 更多 / 收起），可收起为 30pt 小圆钮，收起状态自动记住
- 💾 **连接管理**：卡片列表、滑动删除、复制链接
- 🔄 **自动恢复**：重新打开 App 直接回到上次的连接画面；主动退出（返回按钮）后才回列表
- 📤 **文件上传**：远程页里的图片/文件上传走系统照片选择器（PHPicker）/ 文件选择器，**无需存储权限**
- 📲 **iPhone + iPad** 通用（Universal）

## 使用教程

与 Android 版共用一份图文教程（电脑端二维码获取步骤 + 官方注意事项），见
[Android 仓库 README](https://github.com/Deep-AI-Evo/zcode-remote-apk#使用教程--usage)。

简单说：电脑端 ZCode **左下角侧栏 → 手机图标** → 弹窗左侧二维码/复制链接 → 本 App 扫码或粘贴。

## 构建 / Build

要求：Xcode 15+（iOS 16.0 SDK 起），无需第三方依赖。

```bash
xcodegen generate      # 已提供预生成的 ZCodeRemote.xcodeproj，可跳过
open ZCodeRemote.xcodeproj
```

- **模拟器**：选 iPhone 模拟器直接 ⌘R
- **真机**：Signing & Capabilities 里选择你自己的开发者 Team（自动签名），连接 iPhone/iPad 后 ⌘R

## 项目结构 / Structure

```
Sources/
├── ZCodeRemoteApp.swift      # @main
├── Stores/ConnectionsStore.swift   # 连接存储（UserDefaults）+ 最后连接恢复
└── Views/
    ├── HomeView.swift        # 连接列表 / 空态 / 恢复上次连接
    ├── AddLinkView.swift     # 粘贴导入 + 扫码入口
    ├── QRScannerView.swift   # DataScanner 扫码（相机权限）
    └── ConnectView.swift     # WKWebView + 浮动工具条 + 文件上传
```

## 免责声明 / Disclaimer

本项目是第三方非官方客户端，仅把 ZCode 官方提供的「手机连接」网页封装为本地应用，不修改、不绕过任何官方协议或鉴权。与智谱/ZCode 无隶属关系。

## 许可证 / License

[MIT](LICENSE)

---

**壹我AI** 制作 · Made by 壹我AI