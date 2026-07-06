import SwiftUI

/// 추가/수정 화면의 커스텀 필드 한 행 — Design.md 2.4③.
/// [라벨 입력(점선 밑줄) · 값 입력(모노) · 제거(−) 원형 버튼].
/// 표시·바인딩만 담당한다 — 초안 배열 조작(추가/삭제)은 상위 ViewModel이 맡는다.
struct CustomFieldRow: View {
    @Binding var label: String
    @Binding var value: String
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: MASpacing.gap) {
            TextField("라벨", text: $label)
                .font(MAType.fieldLabel)
                .foregroundStyle(MAColor.fieldLabel)
                .tint(MAColor.primary)
                .autocorrectionDisabled()
                .frame(width: 88)
                .overlay(alignment: .bottom) { DashedUnderline() }

            TextField("값", text: $value)
                .font(MAType.secretValue)
                .foregroundStyle(MAColor.ink)
                .tint(MAColor.primary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .frame(maxWidth: .infinity, alignment: .leading)

            removeButton
        }
        .padding(.horizontal, MASpacing.rowHorizontal)
        .padding(.vertical, 10)
    }

    /// 제거(−) 원형 버튼 — 연한 붉은 바탕에 destructive 아이콘(Design.md 2.4③).
    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "minus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(MAColor.destructive)
                .frame(width: 28, height: 28)
                .background(MAColor.destructiveBG)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// 라벨 입력 밑 점선 밑줄 — Design.md 2.4③의 라벨 필드 표식.
private struct DashedUnderline: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .foregroundStyle(MAColor.secondaryAlt.opacity(0.5))
        }
        .frame(height: 1)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var label = "PIN"
        @State private var value = "123456"
        var body: some View {
            CustomFieldRow(label: $label, value: $value, onRemove: {})
                .background(MAColor.card)
                .clipShape(RoundedRectangle(cornerRadius: MARadius.card, style: .continuous))
                .padding()
                .background(MAColor.appBackground)
        }
    }
    return PreviewHost()
}
