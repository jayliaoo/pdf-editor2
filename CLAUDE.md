# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A SwiftUI-based macOS PDF editor application using PDFKit for PDF manipulation. Supports viewing, editing, and organizing PDF documents with features like page extraction, insertion, rotation, reordering, and deletion.

## Build Commands

```bash
# Build the project
xcodebuild -scheme PDFEditor -destination 'platform=macOS' build

# Or open in Xcode
open PDFEditor.xcodeproj
```

## Architecture

- **UI Framework**: SwiftUI
- **PDF Processing**: PDFKit
- **State Management**: @Observable (Swift 5.9+)
- **Architecture Pattern**: MVVM

### Key Components

- `PDFEditorState` - Central state manager using `@Observable` macro, handles document state, page operations (delete, rotate, move, insert), and thumbnail caching
- `ContentViewModel` - ObservableObject bridging notifications to state actions
- `ContentView` - Main layout with three-panel design (thumbnails, preview, tool panel)

### Directory Structure

```
PDFEditor/
├── PDFEditorApp.swift       # App entry point with menu commands
├── Views/                   # SwiftUI views
│   ├── ContentView.swift    # Main layout with drag-drop support
│   ├── ThumbnailSidebarView.swift
│   ├── ThumbnailItemView.swift
│   ├── PDFPreviewView.swift
│   ├── ToolPanelView.swift
│   └── EmptyStateView.swift
├── ViewModels/
│   ├── PDFEditorState.swift           # Core state (@Observable)
│   └── PDFEditorState+Actions.swift   # PDF operations extension
└── Utilities/
    ├── ThumbnailGenerator.swift
    ├── ThumbnailCacheManager.swift
    └── NotificationNames.swift
```

## Important Implementation Details

- **macOS 14.0+** deployment target required (uses @Observable)
- **Xcode 15.0+** required
- **Swift 5.9+** required
- Menu commands are defined in `PDFEditorApp.swift` using NotificationCenter for communication
- File operations (open, save, export) triggered via custom Notification names
- Drag-and-drop support in ContentView for PDF files
- Thumbnail cache is rebuilt when page order changes

## Superpowers Workflow

This project uses Superpowers for development workflow. Key skills to use:

- `/brainstorm` - Use before any creative work (features, components, functionality)
- `/tdd` - Use when implementing features or bugfixes
- `/debug` - Use when encountering bugs or unexpected behavior
- `/verify` - Use before claiming work is complete
- `/review` - Use when completing tasks or before merging

See available skills in system reminder for full list.

## Keyboard Shortcuts

- `⌘O`: Open file
- `⌘W`: Close window
- `⌘S`: Save
- `⌘⇧S`: Save As
- `⌘⇧E`: Export current page
- `⌘⇧R`: Rotate clockwise
- `⌘⌥R`: Rotate counterclockwise
- `⌘Delete`: Delete current page