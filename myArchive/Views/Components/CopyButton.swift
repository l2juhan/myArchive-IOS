import SwiftUI

/// 필드별 복사 버튼 — Design.md 2.3 / 3.6.
/// 38×38 회색 바탕에 주황 복사 아이콘. 복사 직후 1.3초간 초록 체크로 전이(F-4).
struct CopyButton: View {
    let action: () -> Void

    @State private var isCopied = false

    var body: some View {
        Button {
            action()
            isCopied = true
            Task {
                try? await Task.sleep(for: .seconds(1.3))
                isCopied = false
            }
        } label: {
            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isCopied ? MAColor.success : MAColor.accent)
                .frame(width: 38, height: 38)
                .background(MAColor.copyButtonBG)
                .clipShape(RoundedRectangle(cornerRadius: MARadius.copyButton, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isCopied)
        .accessibilityLabel(isCopied ? "복사됨" : "복사")
    }
}

#Preview {
    CopyButton(action: {})
        .padding()
        .background(MAColor.appBackground)
}
