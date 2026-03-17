import Foundation
import PDFKit

/// PDF 编辑器状态管理类
/// 使用 @Observable 宏实现 SwiftUI 状态管理
@Observable
class PDFEditorState {
    /// 当前 PDF 文档
    var currentDocument: PDFDocument?

    /// 当前文档的原始路径
    var currentDocumentURL: URL?

    /// 文档是否有未保存的更改
    var hasUnsavedChanges: Bool = false

    /// 当前页面索引
    var currentPageIndex: Int = 0

    /// 选中的页面索引集合
    var selectedPages: Set<Int> = []

    /// 缩略图缓存
    var thumbnailCache: [Int: NSImage] = [:]

    /// 侧边栏是否可见
    var isSidebarVisible: Bool = true

    /// 缩放比例
    var zoomScale: CGFloat = 1.0

    /// 页面总数
    var pageCount: Int {
        currentDocument?.pageCount ?? 0
    }

    /// 是否有文档加载
    var hasDocument: Bool {
        currentDocument != nil
    }

    /// 加载 PDF 文档
    /// - Parameter url: PDF 文件 URL
    /// - Returns: 是否加载成功
    func loadDocument(url: URL) -> Bool {
        guard let document = PDFDocument(url: url) else {
            return false
        }
        currentDocument = document
        currentDocumentURL = url
        hasUnsavedChanges = false
        currentPageIndex = 0
        selectedPages.removeAll()
        thumbnailCache.removeAll()
        return true
    }

    /// 保存文档到当前路径
    /// - Returns: 是否保存成功
    func save() -> Bool {
        guard let document = currentDocument,
              let url = currentDocumentURL else { return false }
        return document.write(to: url)
    }

    /// 另存为新文件
    /// - Parameter url: 新文件路径
    /// - Returns: 是否保存成功
    func saveAs(to url: URL) -> Bool {
        guard let document = currentDocument else { return false }
        let success = document.write(to: url)
        if success {
            currentDocumentURL = url
            hasUnsavedChanges = false
        }
        return success
    }

    /// 检查文档是否有保存的路径
    var canSave: Bool {
        currentDocument != nil && currentDocumentURL != nil
    }

    /// 清空当前文档
    func clearDocument() {
        currentDocument = nil
        currentDocumentURL = nil
        hasUnsavedChanges = false
        currentPageIndex = 0
        selectedPages.removeAll()
        thumbnailCache.removeAll()
    }

    /// 删除指定页面
    /// - Parameter indices: 要删除的页面索引集合
    func deletePages(_ indices: Set<Int>) {
        guard let document = currentDocument else { return }

        // 从大到小排序，避免删除后索引偏移
        let sortedIndices = indices.sorted(by: >)

        for index in sortedIndices {
            if index >= 0 && index < document.pageCount {
                document.removePage(at: index)
            }
        }

        // 调整当前页索引
        if currentPageIndex >= document.pageCount {
            currentPageIndex = max(0, document.pageCount - 1)
        }

        selectedPages.removeAll()
        hasUnsavedChanges = true
        rebuildThumbnailCache()

        // 强制触发视图更新
        currentDocument = document
    }

    /// 删除页码范围
    /// - Parameters:
    ///   - from: 起始页
    ///   - to: 结束页
    func deletePageRange(from: Int, to: Int) {
        var indices = Set<Int>()
        for i in from...to {
            indices.insert(i)
        }
        deletePages(indices)
    }

    /// 旋转页面
    /// - Parameters:
    ///   - pageIndex: 页面索引
    ///   - clockwise: 是否顺时针旋转
    func rotatePage(at pageIndex: Int, clockwise: Bool) {
        guard let document = currentDocument,
              let page = document.page(at: pageIndex) else { return }

        let currentRotation = page.rotation
        let newRotation = clockwise
            ? (currentRotation + 90) % 360
            : (currentRotation - 90 + 360) % 360
        page.rotation = newRotation

        // 标记有未保存的更改
        hasUnsavedChanges = true

        // 清除该页面的缩略图缓存
        thumbnailCache.removeValue(forKey: pageIndex)
    }

    /// 重建缩略图缓存（页面顺序变化后调用）
    func rebuildThumbnailCache() {
        thumbnailCache.removeAll()
    }

    /// 移动页面到新位置
    /// - Parameters:
    ///   - from: 源页面索引
    ///   - to: 目标页面索引
    func movePage(from: Int, to: Int) {
        guard let document = currentDocument,
              let page = document.page(at: from)?.copy() as? PDFPage else { return }

        // 移除源页面
        document.removePage(at: from)

        // 计算目标位置（考虑移除后的偏移）
        var adjustedTo = to
        if from < to {
            adjustedTo = to - 1
        }

        // 插入到目标位置
        document.insert(page, at: min(adjustedTo, document.pageCount))

        // 更新当前页索引
        if from == currentPageIndex {
            currentPageIndex = min(to, document.pageCount - 1)
        } else if from < currentPageIndex && to >= currentPageIndex {
            currentPageIndex -= 1
        } else if from > currentPageIndex && to <= currentPageIndex {
            currentPageIndex += 1
        }

        // 标记有未保存的更改
        hasUnsavedChanges = true

        // 重建缩略图缓存
        rebuildThumbnailCache()
    }
}
