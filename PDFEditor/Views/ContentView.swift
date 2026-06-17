import SwiftUI
import PDFKit
import AppKit

class ContentViewModel: ObservableObject {
    @Published var state = PDFEditorState()
    @Published var showImageExtractionDialog = false
    @Published var extractedImages: [ExtractedImage] = []
    private var observers: [NSObjectProtocol] = []

    init() {
        setupNotifications()
    }

    private func setupNotifications() {
        let obs1 = NotificationCenter.default.addObserver(forName: .openFile, object: nil, queue: .main) { [weak self] _ in
            self?.openPDF()
        }
        let obs2 = NotificationCenter.default.addObserver(forName: .exportCurrentPage, object: nil, queue: .main) { [weak self] _ in
            self?.exportCurrentPage()
        }
        let obs3 = NotificationCenter.default.addObserver(forName: .rotateClockwise, object: nil, queue: .main) { [weak self] _ in
            if let self = self {
                self.state.rotatePage(at: self.state.currentPageIndex, clockwise: true)
            }
        }
        let obs4 = NotificationCenter.default.addObserver(forName: .rotateCounterclockwise, object: nil, queue: .main) { [weak self] _ in
            if let self = self {
                self.state.rotatePage(at: self.state.currentPageIndex, clockwise: false)
            }
        }
        let obs5 = NotificationCenter.default.addObserver(forName: .deleteCurrentPage, object: nil, queue: .main) { [weak self] _ in
            guard let self = self, self.state.hasDocument else { return }
            self.state.deletePages([self.state.currentPageIndex])
        }
        let obs6 = NotificationCenter.default.addObserver(forName: .deletePage, object: nil, queue: .main) { [weak self] notification in
            guard let self = self, self.state.hasDocument else { return }
            if let pageIndex = notification.userInfo?["pageIndex"] as? Int {
                self.state.deletePages([pageIndex])
            }
        }
        let obs7 = NotificationCenter.default.addObserver(forName: .insertImage, object: nil, queue: .main) { [weak self] _ in
            self?.insertImage()
        }
        let obs8 = NotificationCenter.default.addObserver(forName: .insertPDF, object: nil, queue: .main) { [weak self] _ in
            self?.insertPDF()
        }
        let obs9 = NotificationCenter.default.addObserver(forName: .saveDocument, object: nil, queue: .main) { [weak self] _ in
            self?.saveDocument()
        }
        let obs10 = NotificationCenter.default.addObserver(forName: .saveDocumentAs, object: nil, queue: .main) { [weak self] _ in
            self?.saveDocumentAs()
        }
        let obs11 = NotificationCenter.default.addObserver(forName: .extractImages, object: nil, queue: .main) { [weak self] _ in
            self?.extractImages()
        }
        observers = [obs1, obs2, obs3, obs4, obs5, obs6, obs7, obs8, obs9, obs10, obs11]
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func openPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            _ = state.loadDocument(url: url)
        }
    }

    func exportCurrentPage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Page_\(state.currentPageIndex + 1)"
        if panel.runModal() == .OK, let url = panel.url {
            _ = state.exportPageAsImage(pageIndex: state.currentPageIndex, to: url)
        }
    }

    func insertImage() {
        guard state.hasDocument else { return }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .gif]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                // 插入到当前页之后
                let insertIndex = state.currentPageIndex + 1
                if state.insertImage(image, at: insertIndex) {
                    // 插入成功后，选中新插入的页面
                    state.selectedPages = [insertIndex] as Set
                    state.currentPageIndex = insertIndex
                }
            }
        }
    }

    func insertPDF() {
        guard state.hasDocument else { return }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            // 插入到当前页之后
            let insertIndex = state.currentPageIndex + 1
            if state.insertPDF(from: url, at: insertIndex) {
                // 插入成功后，选中新插入的页面
                if let sourceDoc = PDFDocument(url: url) {
                    let pageCount = sourceDoc.pageCount
                    let endIndex = insertIndex + pageCount - 1
                    state.selectedPages = Set(insertIndex...endIndex)
                    state.currentPageIndex = insertIndex
                }
            }
        }
    }

    func saveDocument() {
        guard state.canSave else { return }

        if state.save() {
            state.hasUnsavedChanges = false
        } else {
            let alert = NSAlert()
            alert.messageText = "保存失败"
            alert.informativeText = "无法保存文档，请检查文件权限。"
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    func saveDocumentAs() {
        guard state.hasDocument else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = state.currentDocumentURL?.lastPathComponent ?? "Document.pdf"

        if panel.runModal() == .OK, let url = panel.url {
            if state.saveAs(to: url) {
                state.hasUnsavedChanges = false
            } else {
                let alert = NSAlert()
                alert.messageText = "保存失败"
                alert.informativeText = "无法保存文档，请检查文件权限。"
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }

    func extractImages() {
        guard state.hasDocument else { return }

        let images = state.extractImagesFromSelectedPages()

        if images.isEmpty {
            let alert = NSAlert()
            alert.messageText = "未找到图片"
            alert.informativeText = "选中的页面中没有找到可提取的图片。"
            alert.alertStyle = .informational
            alert.runModal()
            return
        }

        extractedImages = images
        showImageExtractionDialog = true
    }

    func saveExtractedImages(_ images: [ExtractedImage]) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "选择保存图片的目录"

        if panel.runModal() == .OK, let url = panel.url {
            let count = state.saveExtractedImages(images, to: url)

            let alert = NSAlert()
            alert.messageText = "提取成功"
            alert.informativeText = "成功保存 \(count) 张图片到:\n\(url.path)"
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    private var state: PDFEditorState { viewModel.state }
    @State private var sidebarWidth: CGFloat = 140
    @State private var isDragging = false

    var body: some View {
        HStack(spacing: 0) {
            if state.isSidebarVisible {
                ThumbnailSidebarView(state: state, thumbnailWidth: sidebarWidth - 16)
                    .frame(width: sidebarWidth)

                // 可拖动的分割区域
                Rectangle()
                    .fill(isDragging ? Color.accentColor.opacity(0.5) : Color.clear)
                    .frame(width: 6)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                isDragging = true
                                let newWidth = sidebarWidth + value.translation.width
                                sidebarWidth = min(max(newWidth, 80), 300)
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                    .onHover { hovering in
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
            }

            PDFPreviewView(state: state)
                .frame(minWidth: 400)

            ToolPanelView(state: state)
                .frame(minWidth: 180, minHeight: 150)
        }
        .overlay {
            if !state.hasDocument {
                EmptyStateView(onOpenFile: { viewModel.openPDF() })
            }
        }
        .onDrop(of: [.fileURL], delegate: FileDropDelegate { url in
            state.loadDocument(url: url)
        })
        .sheet(isPresented: $viewModel.showImageExtractionDialog) {
            ImageExtractionDialogView(images: viewModel.extractedImages) { selectedImages in
                viewModel.saveExtractedImages(selectedImages)
            }
        }
    }
}

struct FileDropDelegate: DropDelegate {
    let onDrop: (URL) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        for provider in info.itemProviders(for: [.fileURL]) {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        onDrop(url)
                    }
                }
            }
        }
        return true
    }
}

#Preview {
    ContentView()
}
