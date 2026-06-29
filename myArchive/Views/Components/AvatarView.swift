import SwiftUI

/// 이니셜 아바타 — 목록(42)·상세(62) 공용. Design.md 2.2 / 2.3.
/// 계정 색(F-15)을 배경으로, 밝은 색이면 잉크색 이니셜로 가독성 보정.
struct AvatarView: View {
    let initial: String
    let colorHex: String
    let size: CGFloat

    private var radius: CGFloat {
        size >= 60 ? MARadius.detailAvatar : MARadius.listAvatar
    }

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color(hex: colorHex))
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(MAAvatarPalette.foreground(on: colorHex))
            )
            .overlay(
                // 흰색 스와치 경계 보강
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(MAColor.divider, lineWidth: colorHex.uppercased() == "#FFFFFF" ? 1 : 0)
            )
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(initial: "N", colorHex: "#03C75A", size: 42)
        AvatarView(initial: "T", colorHex: "#3182F6", size: 62)
        AvatarView(initial: "K", colorHex: "#FEE500", size: 42)
    }
    .padding()
    .background(MAColor.appBackground)
}
