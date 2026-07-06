import SwiftUI

/// 재사용 토글 스위치 — Design.md 1.4 / 2.4⑤.
/// 51×31 pill 트랙 위로 27px 흰 노브가 좌(꺼짐)↔우(켜짐)로 미끄러진다.
/// 값은 `isOn` 바인딩만 갱신하며, 저장·부수효과는 호출부(ViewModel)가 맡는다.
struct MAToggle: View {
    @Binding var isOn: Bool

    private let trackWidth: CGFloat = 51
    private let trackHeight: CGFloat = 31
    private let knobSize: CGFloat = 27

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? MAColor.primary : MAColor.toggleOff)
                .frame(width: trackWidth, height: trackHeight)

            Circle()
                .fill(MAColor.card)
                .frame(width: knobSize, height: knobSize)
                .shadow(color: .black.opacity(0.15), radius: 1.5, x: 0, y: 1)
                .padding(.horizontal, (trackHeight - knobSize) / 2)
        }
        .contentShape(Capsule())
        .onTapGesture {
            withAnimation(MAMotion.segment) { isOn.toggle() }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "켜짐" : "꺼짐")
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var on = true
        @State private var off = false

        var body: some View {
            VStack(spacing: 24) {
                MAToggle(isOn: $on)
                MAToggle(isOn: $off)
            }
            .padding()
            .background(MAColor.appBackground)
        }
    }
    return PreviewHost()
}
