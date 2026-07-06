import SwiftUI

/// 상세 화면 타임스탬프 칩 — Design.md 2.3.
/// 회색 배경 위 보조 텍스트("N일 전 수정" 등)를 담는 정적 칩.
struct MATimestampChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(MAType.caption)
            .foregroundStyle(MAColor.secondaryAlt)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(MAColor.chipBG)
            .clipShape(RoundedRectangle(cornerRadius: MARadius.segment, style: .continuous))
    }
}

/// 상세 화면 즐겨찾기 토글 칩 — Design.md 2.3.
/// 활성: 살구빛 배경 + 채워진 별. 비활성: 회색 배경 + 빈 별.
/// 값은 `isOn` 바인딩만 갱신하며, 저장은 호출부(ViewModel)가 맡는다.
struct MAFavoriteChip: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isOn ? "star.fill" : "star")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isOn ? MAColor.accent : MAColor.secondary)
            Text("즐겨찾기")
                .font(MAType.caption)
                .foregroundStyle(isOn ? MAColor.favChipText : MAColor.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isOn ? MAColor.favChipBG : MAColor.chipBG)
        .clipShape(RoundedRectangle(cornerRadius: MARadius.segment, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(MAMotion.segment) { isOn.toggle() }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "켜짐" : "꺼짐")
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var fav = true
        @State private var notFav = false

        var body: some View {
            VStack(spacing: 16) {
                MATimestampChip(text: "3일 전 수정")
                MAFavoriteChip(isOn: $fav)
                MAFavoriteChip(isOn: $notFav)
            }
            .padding()
            .background(MAColor.appBackground)
        }
    }
    return PreviewHost()
}
