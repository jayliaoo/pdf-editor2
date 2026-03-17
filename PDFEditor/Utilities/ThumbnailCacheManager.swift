import AppKit

/// 缩略图缓存管理器
class ThumbnailCacheManager {
    static let shared = ThumbnailCacheManager()

    private var cache = NSCache<NSNumber, NSImage>()
    private let maxCacheSize = 50

    init() {
        cache.countLimit = maxCacheSize
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    /// 从缓存获取图片
    func image(forKey key: Int) -> NSImage? {
        cache.object(forKey: NSNumber(value: key))
    }

    /// 设置缓存图片
    func setImage(_ image: NSImage, forKey key: Int) {
        cache.setObject(image, forKey: NSNumber(value: key))
    }

    /// 移除缓存
    func removeImage(forKey key: Int) {
        cache.removeObject(forKey: NSNumber(value: key))
    }

    /// 清空所有缓存
    @objc func clearCache() {
        cache.removeAllObjects()
    }
}
