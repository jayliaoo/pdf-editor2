import Foundation
import PDFKit
import AppKit
import CoreGraphics

/// PDF 页面中的图片信息
struct ExtractedImage: Identifiable {
    let id = UUID()
    let image: NSImage
    let data: Data
    let width: Int
    let height: Int
    let format: ImageFormat
    let pageIndex: Int

    enum ImageFormat {
        case jpeg
        case png
        case unknown

        var fileExtension: String {
            switch self {
            case .jpeg: return "jpg"
            case .png: return "png"
            case .unknown: return "png"
            }
        }
    }
}

/// PDF 图片提取器
class ImageExtractor {
    /// 从 PDF 页面中提取所有图片
    /// - Parameter page: PDF 页面
    /// - Returns: 提取的图片数组
    static func extractImages(from page: PDFPage, pageIndex: Int) -> [ExtractedImage] {
        var images: [ExtractedImage] = []

        guard let cgPage = page.pageRef else {
            return images
        }

        let pageDict = cgPage.dictionary

        // 使用 Objective-C 辅助类获取所有键名
        guard let xObjectsDict = getXObjectsDictionary(from: pageDict) else {
            return images
        }

        let keys = PDFDictionaryHelper.allKeys(from: xObjectsDict)

        // 遍历所有键，尝试提取图片
        for key in keys {
            if let image = extractImageByKey(key, from: pageDict, pageIndex: pageIndex) {
                images.append(image)
            }
        }

        return images
    }

    /// 获取 XObject 字典
    private static func getXObjectsDictionary(from pageDict: CGPDFDictionaryRef?) -> CGPDFDictionaryRef? {
        guard let pageDict = pageDict else { return nil }

        var resourcesDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
              let resources = resourcesDict else {
            return nil
        }

        var xObjectDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(resources, "XObject", &xObjectDict) else {
            return nil
        }

        return xObjectDict
    }

    /// 从多个页面提取图片
    /// - Parameter pages: 页面索引和 PDF 文档
    /// - Returns: 所有提取的图片
    static func extractImages(from document: PDFDocument, pageIndices: [Int]) -> [ExtractedImage] {
        var allImages: [ExtractedImage] = []

        for index in pageIndices {
            guard let page = document.page(at: index) else {
                continue
            }
            let images = extractImages(from: page, pageIndex: index)
            allImages.append(contentsOf: images)
        }

        return allImages
    }

    /// 保存图片到目录
    /// - Parameters:
    ///   - images: 要保存的图片
    ///   - directory: 目标目录
    /// - Returns: 成功保存的文件 URL 数组
    static func saveImages(_ images: [ExtractedImage], to directory: URL) -> [URL] {
        var savedURLs: [URL] = []

        for (index, image) in images.enumerated() {
            let fileName = "Image_\(index + 1).\(image.format.fileExtension)"
            let fileURL = directory.appendingPathComponent(fileName)

            do {
                try image.data.write(to: fileURL)
                savedURLs.append(fileURL)
            } catch {
                print("Failed to save image: \(error)")
            }
        }

        return savedURLs
    }

    // MARK: - Private Helpers

    private static func extractImageByKey(_ key: String, from pageDict: CGPDFDictionaryRef?, pageIndex: Int) -> ExtractedImage? {
        guard let pageDict = pageDict else { return nil }

        // 获取 Resources
        var resourcesDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
              let resources = resourcesDict else {
            return nil
        }

        // 获取 XObject
        var xObjectDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(resources, "XObject", &xObjectDict),
              let xObjects = xObjectDict else {
            return nil
        }

        // 尝试获取指定键的对象
        var object: CGPDFObjectRef?
        guard key.withCString({ cKey in
            CGPDFDictionaryGetObject(xObjects, cKey, &object)
        }), let obj = object else {
            return nil
        }

        return extractImage(from: obj, pageIndex: pageIndex)
    }

    private static func extractImage(from object: CGPDFObjectRef, pageIndex: Int) -> ExtractedImage? {
        var stream: CGPDFStreamRef?
        guard CGPDFObjectGetValue(object, .stream, &stream),
              let imageStream = stream else {
            return nil
        }

        // 获取图片数据
        var format: CGPDFDataFormat = .raw
        guard let cfData = CGPDFStreamCopyData(imageStream, &format),
              let data = cfData as Data? else {
            return nil
        }

        // 获取图片字典
        guard let dict = CGPDFStreamGetDictionary(imageStream) else {
            return nil
        }

        // 检查 Subtype 是否为 Image
        var subtypePtr: UnsafePointer<CChar>?
        guard CGPDFDictionaryGetName(dict, "Subtype", &subtypePtr),
              let subtypeName = subtypePtr else {
            return nil
        }

        let subtypeStr = String(cString: subtypeName)
        guard subtypeStr == "Image" else {
            return nil
        }

        // 获取尺寸
        var width: CGPDFInteger = 0
        var height: CGPDFInteger = 0
        CGPDFDictionaryGetInteger(dict, "Width", &width)
        CGPDFDictionaryGetInteger(dict, "Height", &height)

        // 尝试创建 NSImage
        guard let image = NSImage(data: data) else {
            return nil
        }

        // 检测格式
        let imageFormat = detectFormat(from: dict, data: data)

        return ExtractedImage(
            image: image,
            data: data,
            width: Int(width),
            height: Int(height),
            format: imageFormat,
            pageIndex: pageIndex
        )
    }

    private static func detectFormat(from dict: CGPDFDictionaryRef, data: Data) -> ExtractedImage.ImageFormat {
        // 检查 Filter 字段
        var filterObj: CGPDFObjectRef?
        if CGPDFDictionaryGetObject(dict, "Filter", &filterObj),
           let filter = filterObj {
            var filterStr: CGPDFStringRef?
            if CGPDFObjectGetValue(filter, .string, &filterStr),
               let str = filterStr {
                if let cfStr = CGPDFStringCopyTextString(str) {
                    let name = cfStr as String
                    if name.contains("DCTDecode") {
                        return .jpeg
                    } else if name.contains("FlateDecode") {
                        return .png
                    }
                }
            }
        }

        // 通过数据特征检测
        if data.starts(with: [0xFF, 0xD8, 0xFF]) {
            return .jpeg
        } else if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return .png
        }

        return .unknown
    }
}
