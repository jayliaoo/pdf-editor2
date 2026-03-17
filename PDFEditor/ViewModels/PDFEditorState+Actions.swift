import Foundation
import PDFKit
import AppKit

// MARK: - PDF 文档操作扩展
extension PDFEditorState {
    /// 插入图片为 PDF 页面
    /// - Parameters:
    ///   - image: 要插入的图片
    ///   - index: 插入位置
    /// - Returns: 是否成功
    func insertImage(_ image: NSImage, at index: Int) -> Bool {
        guard let document = currentDocument else { return false }

        // 获取文档中第一页的尺寸作为参考
        let documentSize: CGSize
        if let firstPage = document.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            documentSize = bounds.size
        } else {
            documentSize = CGSize(width: 612, height: 792) // 默认 Letter 尺寸
        }

        // 获取图片尺寸
        let imageSize = image.size
        let isImageLandscape = imageSize.width > imageSize.height
        let isDocumentLandscape = documentSize.width > documentSize.height

        // 计算最终尺寸：如果图片方向与文档方向不一致，则交换宽高
        let finalSize: CGSize
        if isImageLandscape != isDocumentLandscape {
            // 方向不一致，交换宽高以匹配文档方向
            finalSize = CGSize(width: documentSize.height, height: documentSize.width)
        } else {
            // 方向一致，使用文档尺寸（保持比例适配）
            finalSize = documentSize
        }

        // 调整图片以适应目标尺寸
        let adjustedImage = resizeImage(image, to: finalSize)

        // 创建 PDF 从调整后的图片数据
        guard let pdfData = createPDF(from: adjustedImage, size: finalSize) else {
            return false
        }

        // 从 PDF 数据加载页面
        guard let tempDoc = PDFDocument(data: pdfData),
              let newPage = tempDoc.page(at: 0)?.copy() as? PDFPage else {
            return false
        }

        document.insert(newPage, at: min(index, document.pageCount))
        hasUnsavedChanges = true
        rebuildThumbnailCache()
        return true
    }

    /// 调整图片尺寸，保持比例填充
    private func resizeImage(_ image: NSImage, to targetSize: CGSize) -> NSImage {
        let originalSize = image.size
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        let scale = max(widthRatio, heightRatio) // 使用较大的比例以确保填满

        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        resizedImage.unlockFocus()

        return resizedImage
    }

    /// 从 NSImage 创建 PDF 数据
    private func createPDF(from image: NSImage, size: CGSize) -> Data? {
        let pdfInfo: [CFString: Any] = [
            kCGPDFContextCreator: "PDF Editor",
            kCGPDFContextAuthor: "PDF Editor User"
        ]

        let imageData = NSMutableData()
        guard let pdfConsumer = CGDataConsumer(data: imageData as CFMutableData) else {
            return nil
        }

        // 使用指定的尺寸
        var mediaBox = CGRect(origin: .zero, size: size)

        guard let context = CGContext(
            consumer: pdfConsumer,
            mediaBox: &mediaBox,
            pdfInfo as CFDictionary
        ) else {
            return nil
        }

        context.beginPDFPage(nil)

        // 绘制图片（居中绘制）
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            // 计算居中位置
            let imageRect = CGRect(
                x: (size.width - image.size.width) / 2,
                y: (size.height - image.size.height) / 2,
                width: image.size.width,
                height: image.size.height
            )
            context.draw(cgImage, in: imageRect)
        }

        context.endPDFPage()
        context.closePDF()

        return imageData as Data
    }

    /// 插入 PDF 文件
    /// - Parameters:
    ///   - url: PDF 文件 URL
    ///   - index: 插入位置
    /// - Returns: 是否成功
    func insertPDF(from url: URL, at index: Int) -> Bool {
        guard let document = currentDocument,
              let sourceDoc = PDFDocument(url: url) else { return false }

        // 从后往前插入，保持原有顺序
        for i in stride(from: sourceDoc.pageCount - 1, through: 0, by: -1) {
            if let page = sourceDoc.page(at: i)?.copy() as? PDFPage {
                document.insert(page, at: min(index, document.pageCount))
            }
        }

        rebuildThumbnailCache()
        return true
    }

    /// 导出页面为图片
    /// - Parameters:
    ///   - pageIndex: 页面索引
    ///   - url: 保存路径
    /// - Returns: 是否成功
    func exportPageAsImage(pageIndex: Int, to url: URL) -> Bool {
        guard let document = currentDocument,
              let page = document.page(at: pageIndex) else { return false }

        // 生成高分辨率图片
        let pageSize = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0
        let imageSize = CGSize(
            width: pageSize.width * scale,
            height: pageSize.height * scale
        )

        let image = page.thumbnail(of: imageSize, for: .mediaBox)

        // 保存为 JPEG
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) {
            try? jpegData.write(to: url)
            return true
        }

        return false
    }

    /// 导出页面为 PDF
    /// - Parameters:
    ///   - pageIndex: 页面索引
    ///   - url: 保存路径
    /// - Returns: 是否成功
    func exportPageAsPDF(pageIndex: Int, to url: URL) -> Bool {
        guard let document = currentDocument,
              let page = document.page(at: pageIndex) else { return false }

        // 获取原始页面的媒体框尺寸
        let pageBounds = page.bounds(for: .mediaBox)
        var mediaBox = pageBounds

        // 创建 PDF 上下文，使用原始页面尺寸
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            return false
        }

        // 开始新页面
        context.beginPDFPage(nil)

        // 绘制页面内容
        page.draw(with: .mediaBox, to: context)

        // 结束并关闭 PDF
        context.endPDFPage()
        context.closePDF()

        return true
    }

    /// 批量导出选中页面
    /// - Parameters:
    ///   - directory: 保存目录
    ///   - asImage: 是否导出为图片（否则为 PDF）
    /// - Returns: 是否成功
    func exportSelectedPages(to directory: URL, asImage: Bool) -> Bool {
        guard !selectedPages.isEmpty else { return false }

        if asImage {
            for (index, pageIndex) in selectedPages.sorted().enumerated() {
                let fileName = "Page_\(pageIndex + 1).png"
                let fileURL = directory.appendingPathComponent(fileName)
                exportPageAsImage(pageIndex: pageIndex, to: fileURL)
            }
        } else {
            let fileName = "SelectedPages.pdf"
            let fileURL = directory.appendingPathComponent(fileName)
            exportPagesAsPDF(to: fileURL)
        }

        return true
    }

    /// 导出选中页面为 PDF
    private func exportPagesAsPDF(to url: URL) {
        guard let document = currentDocument else { return }

        let newDoc = PDFDocument()
        for (index, pageIndex) in selectedPages.sorted().enumerated() {
            if let page = document.page(at: pageIndex)?.copy() as? PDFPage {
                newDoc.insert(page, at: index)
            }
        }

        if let data = newDoc.dataRepresentation() {
            try? data.write(to: url)
        }
    }
}
