import AppKit
import PDFKit

/// 缩略图生成器
struct ThumbnailGenerator {
    /// 低分辨率缩略图尺寸
    static let lowResSize = CGSize(width: 100, height: 140)

    /// 高分辨率缩略图尺寸
    static let highResSize = CGSize(width: 200, height: 280)

    /// 生成低分辨率缩略图
    /// - Parameter page: PDF 页面
    /// - Returns: 低分辨率缩略图
    static func generateLowRes(for page: PDFPage) -> NSImage {
        page.thumbnail(of: lowResSize, for: .mediaBox)
    }

    /// 异步生成高分辨率缩略图
    /// - Parameters:
    ///   - page: PDF 页面
    ///   - completion: 完成回调
    static func generateHighRes(for page: PDFPage, completion: @escaping (NSImage) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = page.thumbnail(of: highResSize, for: .mediaBox)
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
