import SwiftUI

/// 계정 색상 선택 그리드(F-15) — Design.md 1.2 / 2.4②.
/// 9색 프리셋(원형 30px) + 네이티브 무지개 피커를 한 그리드에 배치한다.
/// 선택된 스와치는 링 + 체크로 표시하고, 밝은 색(흰·노랑)은 잉크 체크로 가독성을 보정한다.
/// 값 검증·저장은 하지 않는다 — `selectedHex` 바인딩만 갱신하고 저장은 ViewModel이 맡는다.
struct ColorPickerGrid: View {
    /// 선택된 색의 hex("#RRGGBB"). 프리셋 탭 또는 커스텀 피커 선택으로 갱신된다.
    @Binding var selectedHex: String

    /// 스와치 지름·한 줄 개수는 Design.md 2.4 고정 수치(프리셋 7 + 흰·검·무지개 3).
    private let swatchSize: CGFloat = 30
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(MAAvatarPalette.presets, id: \.hex) { preset in
                swatch(hex: preset.hex)
            }
            rainbowSwatch
        }
        .padding(.horizontal, MASpacing.rowHorizontal)
        .padding(.vertical, MASpacing.cardMargin)
    }

    // MARK: - 프리셋 스와치

    private func swatch(hex: String) -> some View {
        let isSelected = selectedHex.uppercased() == hex.uppercased()
        return Circle()
            .fill(Color(hex: hex))
            .frame(width: swatchSize, height: swatchSize)
            .overlay(
                // 흰색 스와치는 카드(흰 배경)와 겹치므로 경계를 보강한다.
                Circle().stroke(MAColor.divider, lineWidth: hex.uppercased() == "#FFFFFF" ? 1 : 0)
            )
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MAAvatarPalette.foreground(on: hex))
                }
            }
            .overlay {
                // 선택 링 — 스와치 밖으로 살짝 띄운 인디고 원.
                if isSelected {
                    Circle()
                        .stroke(MAColor.primary, lineWidth: 2)
                        .padding(-3)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { selectedHex = hex }
    }

    // MARK: - 네이티브 커스텀 피커(무지개)

    /// 무지개 스와치 = 시스템 `ColorPicker`. 고른 색을 hex로 변환해 `selectedHex`에 반영한다.
    private var rainbowSwatch: some View {
        ColorPicker(selection: customColorBinding, supportsOpacity: false) {
            EmptyView()
        }
        .labelsHidden()
        .frame(width: swatchSize, height: swatchSize)
        .frame(maxWidth: .infinity)
    }

    /// 피커가 오갈 `Color` 바인딩 — 현재 선택색을 보여주고, 새로 고르면 hex로 되돌린다.
    private var customColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: selectedHex.isEmpty ? MAAvatarPalette.defaultHex : selectedHex) },
            set: { selectedHex = $0.toHex() ?? selectedHex }
        )
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var hex = MAAvatarPalette.defaultHex
        var body: some View {
            ColorPickerGrid(selectedHex: $hex)
                .background(MAColor.card)
                .clipShape(RoundedRectangle(cornerRadius: MARadius.card, style: .continuous))
                .padding()
                .background(MAColor.appBackground)
        }
    }
    return PreviewHost()
}
