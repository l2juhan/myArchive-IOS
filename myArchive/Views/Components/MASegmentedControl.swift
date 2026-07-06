import SwiftUI

/// 재사용 세그먼트 컨트롤 — Design.md 1.4 / 설정 화면(05-settings).
/// 회색 pill 트랙 위로 흰색 칩이 선택 항목을 따라 미끄러진다.
/// 값은 `selection` 바인딩만 갱신하며, 저장·부수효과는 호출부(ViewModel)가 맡는다.
struct MASegmentedControl<T: Hashable>: View {
    /// (표시 라벨, 실제 값) 쌍. 균등 분할로 배치된다.
    let options: [(label: String, value: T)]
    @Binding var selection: T

    /// 흰 칩과 트랙 사이 여백 — 칩이 트랙 안에 떠 보이도록 하는 값.
    private let trackPadding: CGFloat = 3

    @Namespace private var chipNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                segment(for: option)
            }
        }
        .padding(trackPadding)
        .background(MAColor.segmentTrack)
        .clipShape(RoundedRectangle(cornerRadius: MARadius.segment + trackPadding, style: .continuous))
    }

    private func segment(for option: (label: String, value: T)) -> some View {
        let isSelected = option.value == selection
        return Text(option.label)
            .font(MAType.rowTitle)
            .foregroundStyle(isSelected ? MAColor.ink : MAColor.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: MARadius.segment, style: .continuous)
                        .fill(MAColor.card)
                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                        .matchedGeometryEffect(id: "selectedChip", in: chipNamespace)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(MAMotion.segment) { selection = option.value }
            }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var expiry: Int = ClipboardExpiry.sixty.rawValue
        @State private var sort: SortMode = .favoriteRecent

        var body: some View {
            VStack(spacing: 24) {
                MASegmentedControl(
                    options: ClipboardExpiry.allCases.map { (label: $0.label, value: $0.rawValue) },
                    selection: $expiry
                )
                MASegmentedControl(
                    options: [
                        (label: "기본", value: SortMode.favoriteRecent),
                        (label: "이름순", value: SortMode.name)
                    ],
                    selection: $sort
                )
            }
            .padding()
            .background(MAColor.appBackground)
        }
    }
    return PreviewHost()
}
