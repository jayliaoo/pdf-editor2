import SwiftUI

struct ThumbnailDropDelegate: DropDelegate {
    let onDrop: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        onDrop()
        return true
    }
}

struct ThumbnailItemView: View {
    let pageIndex: Int
    let image: NSImage?
    let isSelected: Bool
    let isCurrentPage: Bool
    let thumbnailWidth: CGFloat
    let onTap: () -> Void
    let onDrag: () -> Void
    let onDrop: () -> Void
    let onDelete: () -> Void
    let onExport: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(80/112, contentMode: .fit)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.5)
                        )
                }
            }
            .frame(width: thumbnailWidth - 8) // 留出 padding 空间
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isSelected ? Color.blue :
                        isCurrentPage ? Color.green : Color.clear,
                        lineWidth: 3
                    )
            )
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4)

            Text("\(pageIndex + 1)")
                .font(.caption)
                .foregroundColor(isCurrentPage ? .primary : .secondary)
        }
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onDrag {
            onDrag()
            return NSItemProvider(object: NSString(string: "\(pageIndex)"))
        }
        .onDrop(of: [.text], delegate: ThumbnailDropDelegate {
            onDrop()
        })
        .contextMenu {
            Button("删除页面") {
                onDelete()
            }
            Divider()
            Button("导出为图片") {
                onExport()
            }
        }
    }
}

#Preview {
    ThumbnailItemView(
        pageIndex: 0,
        image: NSImage(systemSymbolName: "doc", accessibilityDescription: nil),
        isSelected: false,
        isCurrentPage: true,
        thumbnailWidth: 80,
        onTap: {},
        onDrag: {},
        onDrop: {},
        onDelete: {},
        onExport: {}
    )
}
