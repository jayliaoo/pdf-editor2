import SwiftUI

struct ToolPanelView: View {
    var state: PDFEditorState
    @State private var showInsertMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 页面操作组
            GroupBox("页面操作") {
                VStack(spacing: 8) {
                    ToolButton(
                        icon: "arrow.clockwise",
                        title: "顺时针旋转",
                        action: { rotatePage(clockwise: true) }
                    )
                    .disabled(!state.hasDocument)

                    ToolButton(
                        icon: "arrow.counterclockwise",
                        title: "逆时针旋转",
                        action: { rotatePage(clockwise: false) }
                    )
                    .disabled(!state.hasDocument)

                    Divider()

                    ToolButton(
                        icon: "trash",
                        title: "删除页面",
                        action: deleteSelectedPages,
                        color: .red
                    )
                    .disabled(!state.hasDocument || state.selectedPages.isEmpty)
                }
            }

            // 插入组
            GroupBox("插入") {
                VStack(spacing: 8) {
                    Menu {
                        Button("从文件...") { insertPDF() }
                        Button("从图片...") { insertImage() }
                    } label: {
                        Label("插入页面", systemImage: "plus")
                    }
                    .disabled(!state.hasDocument)
                }
            }

            // 导出组
            GroupBox("导出") {
                VStack(spacing: 8) {
                    ToolButton(
                        icon: "photo",
                        title: "导出为图片",
                        action: { exportPage(asImage: true) }
                    )
                    .disabled(!state.hasDocument)

                    ToolButton(
                        icon: "doc",
                        title: "导出为 PDF",
                        action: { exportPage(asImage: false) }
                    )
                    .disabled(!state.hasDocument)

                    Divider()

                    ToolButton(
                        icon: "square.and.arrow.up.on.square",
                        title: "提取图片",
                        action: { extractImages() }
                    )
                    .disabled(!state.hasDocument)
                }
            }

            Spacer()

            // 文档信息组
            GroupBox("文档信息") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("页数:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(state.pageCount)")
                    }
                    HStack {
                        Text("当前页:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(state.currentPageIndex + 1)")
                    }
                    HStack {
                        Text("已选:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(state.selectedPages.count)")
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(width: 180)
    }

    private func rotatePage(clockwise: Bool) {
        state.rotatePage(at: state.currentPageIndex, clockwise: clockwise)
    }

    private func deleteSelectedPages() {
        guard !state.selectedPages.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = "确认删除"
        alert.informativeText = "确定要删除 \(state.selectedPages.count) 个页面吗？此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            state.deletePages(state.selectedPages)
        }
    }

    private func insertImage() {
        NotificationCenter.default.post(name: .insertImage, object: nil)
    }

    private func insertPDF() {
        NotificationCenter.default.post(name: .insertPDF, object: nil)
    }

    private func extractImages() {
        NotificationCenter.default.post(name: .extractImages, object: nil)
    }

    private func exportPage(asImage: Bool) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = asImage ? [.jpeg] : [.pdf]
        panel.nameFieldStringValue = "Page_\(state.currentPageIndex + 1)"

        if panel.runModal() == .OK, let url = panel.url {
            if asImage {
                _ = state.exportPageAsImage(pageIndex: state.currentPageIndex, to: url)
            } else {
                _ = state.exportPageAsPDF(pageIndex: state.currentPageIndex, to: url)
            }
        }
    }
}

struct ToolButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    var color: Color = .primary

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .lineLimit(1)
                Spacer()
            }
            .foregroundColor(color)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    ToolPanelView(state: PDFEditorState())
}
