# PDF Editor for macOS

一个基于 SwiftUI 和 PDFKit 的 macOS PDF 编辑器应用。

## 功能特性

- 📄 **页面提取**: 提取单页 PDF 为图片或 PDF 文件
- ➕ **页面插入**: 插入图片或 PDF 文件
- 🖼️ **缩略图浏览**: 侧边栏显示所有页面缩略图
- 🎯 **快速导航**: 点击缩略图快速定位到对应页面
- 🗑️ **批量删除**: 支持删除单页、多页或页码范围
- 🔄 **页面旋转**: 支持 90 度倍数旋转
- 📑 **拖拽排序**: 拖拽缩略图重新排列页面顺序

## 系统要求

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## 构建

```bash
# 克隆项目
git clone <repository-url>
cd pdf-editor2

# 打开 Xcode 项目
open PDFEditor.xcodeproj

# 或使用命令行构建
xcodebuild -scheme PDFEditor -destination 'platform=macOS' build
```

## 使用说明

1. 打开应用后，点击"选择文件..."或拖拽 PDF 文件到窗口
2. 使用左侧缩略图浏览和选择页面
3. 使用右侧工具面板进行页面操作
4. 拖拽缩略图可重新排列页面顺序

## 快捷键

- `⌘O`: 打开文件
- `⌘W`: 关闭窗口
- `⌘⇧E`: 导出当前页
- `⌘⇧R`: 顺时针旋转
- `⌘⌥R`: 逆时针旋转
- `⌘Delete`: 删除当前页

## 项目结构

```
PDFEditor/
├── Models/              # 数据模型
├── Views/               # SwiftUI 视图
│   ├── ContentView.swift
│   ├── ThumbnailSidebarView.swift
│   ├── ThumbnailItemView.swift
│   ├── PDFPreviewView.swift
│   ├── ToolPanelView.swift
│   └── EmptyStateView.swift
├── ViewModels/          # 状态管理
│   ├── PDFEditorState.swift
│   └── PDFEditorState+Actions.swift
├── Utilities/           # 工具类
│   ├── ThumbnailGenerator.swift
│   ├── ThumbnailCacheManager.swift
│   └── NotificationNames.swift
└── Resources/           # 资源文件
```

## 技术栈

- **UI 框架**: SwiftUI
- **PDF 处理**: PDFKit
- **状态管理**: @Observable (Swift 5.9+)
- **架构模式**: MVVM

## 许可证

MIT License
