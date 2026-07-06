import SwiftUI

/// 필드별 복사 버튼 — Design.md 2.3 / 3.6.
/// 38×38 회색 바탕에 주황 복사 아이콘. 복사 직후 초록 체크 전이는 M5(F-4)에서 추가한다.
struct CopyButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MAColor.accent)
                .frame(width: 38, height: 38)
                .background(MAColor.copyButtonBG)
                .clipShape(RoundedRectangle(cornerRadius: MARadius.copyButton, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("복사")
    }
}

#Preview {
    CopyButton(action: {})
        .padding()
        .background(MAColor.appBackground)
}
