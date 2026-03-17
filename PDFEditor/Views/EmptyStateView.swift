import SwiftUI

struct EmptyStateView: View {
    let onOpenFile: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("打开 PDF 文档")
                .font(.title)

            Text("拖拽 PDF 文件到此处，或点击下方按钮")
                .foregroundColor(.secondary)

            Button(action: onOpenFile) {
                Label("选择文件...", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    EmptyStateView(onOpenFile: {})
        .frame(width: 400, height: 300)
}
