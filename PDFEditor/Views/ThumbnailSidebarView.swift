import SwiftUI
import PDFKit

struct ThumbnailSidebarView: View {
    var state: PDFEditorState
    var thumbnailWidth: CGFloat
    @State private var thumbnailTasks: [Int: Task<Void, Never>] = [:]
    @State private var draggedPageIndex: Int?
    @State private var lastPageCount: Int = 0

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(0..<state.pageCount, id: \.self) { index in
                    thumbnailView(for: index)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .onChange(of: state.currentDocument) { _, newDocument in
            if newDocument != nil {
                loadAllThumbnails()
            }
        }
        .onChange(of: state.pageCount) { _, newCount in
            // 页面数量变化时，重新加载所有缩略图
            if newCount != lastPageCount {
                lastPageCount = newCount
                cancelAllTasks()
                loadAllThumbnails()
            }
        }
        .onChange(of: state.thumbnailCache) { _, _ in
            // 缩略图缓存被清空时，重新加载
            if state.thumbnailCache.isEmpty && state.hasDocument {
                loadAllThumbnails()
            }
        }
        .onAppear {
            lastPageCount = state.pageCount
            loadAllThumbnails()
        }
    }

    private func thumbnailView(for index: Int) -> some View {
        ThumbnailItemView(
            pageIndex: index,
            image: state.thumbnailCache[index],
            isSelected: state.selectedPages.contains(index),
            isCurrentPage: index == state.currentPageIndex,
            thumbnailWidth: thumbnailWidth,
            onTap: {
                selectPage(index)
            },
            onDrag: {
                draggedPageIndex = index
            },
            onDrop: {
                if let sourceIndex = draggedPageIndex,
                   sourceIndex != index {
                    movePage(from: sourceIndex, to: index)
                }
                draggedPageIndex = nil
            },
            onDelete: {
                deletePage(index)
            },
            onExport: {
                exportPage(index)
            }
        )
    }

    private func selectPage(_ index: Int) {
        state.currentPageIndex = index
        // 单击选择页面
        state.selectedPages = [index]
        NotificationCenter.default.post(
            name: .pageSelected,
            object: nil,
            userInfo: ["pageIndex": index]
        )
    }

    private func movePage(from sourceIndex: Int, to targetIndex: Int) {
        guard let document = state.currentDocument,
              let page = document.page(at: sourceIndex)?.copy() as? PDFPage else { return }

        // 移除源页面
        document.removePage(at: sourceIndex)

        // 计算目标位置（考虑移除后的偏移）
        var adjustedTargetIndex = targetIndex
        if sourceIndex < targetIndex {
            adjustedTargetIndex = targetIndex - 1
        }

        // 插入到目标位置
        document.insert(page, at: min(adjustedTargetIndex, document.pageCount))

        // 更新当前页索引
        if sourceIndex == state.currentPageIndex {
            state.currentPageIndex = min(targetIndex, document.pageCount - 1)
        } else if sourceIndex < state.currentPageIndex && targetIndex >= state.currentPageIndex {
            state.currentPageIndex -= 1
        } else if sourceIndex > state.currentPageIndex && targetIndex <= state.currentPageIndex {
            state.currentPageIndex += 1
        }

        // 刷新缩略图缓存
        state.rebuildThumbnailCache()
    }

    private func deletePage(_ index: Int) {
        state.deletePages([index])
    }

    private func exportPage(_ index: Int) {
        NotificationCenter.default.post(
            name: .exportPage,
            object: nil,
            userInfo: ["pageIndex": index]
        )
    }

    private func loadAllThumbnails() {
        guard let document = state.currentDocument else { return }
        for i in 0..<document.pageCount {
            if state.thumbnailCache[i] == nil {
                loadThumbnail(for: i)
            }
        }
    }

    private func loadThumbnail(for index: Int) {
        thumbnailTasks[index] = Task {
            await MainActor.run {
                guard let document = state.currentDocument,
                      let page = document.page(at: index) else { return }

                let lowRes = ThumbnailGenerator.generateLowRes(for: page)
                state.thumbnailCache[index] = lowRes

                ThumbnailGenerator.generateHighRes(for: page) { image in
                    state.thumbnailCache[index] = image
                }
            }
        }
    }

    private func cancelAllTasks() {
        for (_, task) in thumbnailTasks {
            task.cancel()
        }
        thumbnailTasks.removeAll()
    }
}

#Preview {
    ThumbnailSidebarView(state: PDFEditorState(), thumbnailWidth: 80)
        .frame(width: 140, height: 400)
}
