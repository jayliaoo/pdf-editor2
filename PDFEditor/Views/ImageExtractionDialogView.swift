import SwiftUI

/// 图片提取预览对话框
struct ImageExtractionDialogView: View {
    let images: [ExtractedImage]
    @State private var selectedImages: Set<UUID> = []
    @Environment(\.dismiss) var dismiss

    var onExtract: ([ExtractedImage]) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 16) {
            // 标题和信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("提取图片")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("找到 \(images.count) 张图片")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // 图片网格
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(images) { image in
                        ImageThumbnailView(
                            image: image,
                            isSelected: selectedImages.contains(image.id)
                        ) {
                            toggleSelection(image)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // 底部按钮
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("保存 \(selectedImages.count) 张图片") {
                    let selected = images.filter { selectedImages.contains($0.id) }
                    onExtract(selected)
                    dismiss()
                }
                .disabled(selectedImages.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 700, height: 600)
    }

    private func toggleSelection(_ image: ExtractedImage) {
        if selectedImages.contains(image.id) {
            selectedImages.remove(image.id)
        } else {
            selectedImages.insert(image.id)
        }
    }
}

/// 图片缩略图视图
struct ImageThumbnailView: View {
    let image: ExtractedImage
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // 图片预览
                Image(nsImage: image.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )

                // 选中勾选框
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .background(Circle().fill(Color.white))
                        .padding(4)
                }
            }
            .onTapGesture {
                onTap()
            }

            // 尺寸信息
            Text("\(image.width) × \(image.height)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .cursor(.pointingHand)
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
