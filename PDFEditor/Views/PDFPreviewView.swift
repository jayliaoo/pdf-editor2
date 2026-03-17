import SwiftUI
import PDFKit
import AppKit

struct PDFPreviewView: View {
    var state: PDFEditorState

    var body: some View {
        ZStack {
            if let document = state.currentDocument {
                PDFViewRepresentable(
                    document: document,
                    currentPageIndex: state.currentPageIndex,
                    onPageIndexChange: { newIndex in
                        state.currentPageIndex = newIndex
                    }
                )
            } else {
                Color.gray.opacity(0.1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pageSelected)) { notification in
            if let pageIndex = notification.userInfo?["pageIndex"] as? Int {
                state.currentPageIndex = pageIndex
            }
        }
    }
}

struct PDFViewRepresentable: NSViewRepresentable {
    let document: PDFDocument
    var currentPageIndex: Int
    var onPageIndexChange: (Int) -> Void

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = NSColor.controlBackgroundColor

        context.coordinator.pdfView = pdfView
        context.coordinator.onPageIndexChange = onPageIndexChange

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        if pdfView.document != document {
            pdfView.document = document
        }

        if let page = document.page(at: currentPageIndex),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator {
        weak var pdfView: PDFView?
        var onPageIndexChange: ((Int) -> Void)?

        init(_ parent: PDFViewRepresentable) {
            self.onPageIndexChange = parent.onPageIndexChange
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else { return }

            let index = document.index(for: currentPage)
            onPageIndexChange?(index)
        }
    }
}

#Preview {
    PDFPreviewView(state: PDFEditorState())
}
