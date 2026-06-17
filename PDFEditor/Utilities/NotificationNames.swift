import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let openFile = Notification.Name("openFile")
    static let exportCurrentPage = Notification.Name("exportCurrentPage")
    static let rotateClockwise = Notification.Name("rotateClockwise")
    static let rotateCounterclockwise = Notification.Name("rotateCounterclockwise")
    static let deleteCurrentPage = Notification.Name("deleteCurrentPage")
    static let pageSelected = Notification.Name("pageSelected")
    static let deletePage = Notification.Name("deletePage")
    static let exportPage = Notification.Name("exportPage")
    static let insertImage = Notification.Name("insertImage")
    static let insertPDF = Notification.Name("insertPDF")
    static let saveDocument = Notification.Name("saveDocument")
    static let saveDocumentAs = Notification.Name("saveDocumentAs")
    static let extractImages = Notification.Name("extractImages")
}
