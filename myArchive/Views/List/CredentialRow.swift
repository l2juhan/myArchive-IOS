import SwiftUI

/// 목록 카드 안의 한 행 — Design.md 2.2.
/// [아바타 42] · [제목 + 타임스탬프] · [별 토글] · [chevron].
/// 행 본문 탭(상세 이동)은 부모의 `NavigationLink`가 처리하고,
/// 별 영역만 별도 `Button`으로 즐겨찾기 토글을 가로챈다(제스처 분리).
struct CredentialRow: View {
    let credential: Credential
    let onToggleFavorite: () -> Void

    /// 아바타 크기·별 탭 타깃은 명세 고정 수치(Design.md 2.2).
    static let avatarSize: CGFloat = 42

    var body: some View {
        HStack(spacing: MASpacing.gap) {
            AvatarView(
                initial: credential.initial,
                colorHex: credential.colorHex,
                size: Self.avatarSize
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(credential.serviceName)
                    .font(MAType.rowTitle)
                    .foregroundStyle(MAColor.ink)
                Text(RelativeTime.subtitle(for: credential))
                    .font(MAType.rowSubtitle)
                    .foregroundStyle(MAColor.secondaryAlt)
            }

            Spacer(minLength: MASpacing.gap)

            favoriteButton

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MAColor.placeholder)
        }
        .padding(.horizontal, MASpacing.rowHorizontal)
        .padding(.vertical, MASpacing.rowVertical)
        .contentShape(Rectangle())
    }

    /// 별 토글 — 채워진 별=accent, 빈 별=emptyStar. 34px 탭 타깃.
    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: credential.isFavorite ? "star.fill" : "star")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(credential.isFavorite ? MAColor.accent : MAColor.emptyStar)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 0) {
        CredentialRow(
            credential: Credential(
                serviceName: "네이버", username: "naver_id", passwordRef: "ref1",
                colorHex: "#03C75A", isFavorite: true,
                updatedAt: Date().addingTimeInterval(-8 * 60)
            ),
            onToggleFavorite: {}
        )
        Rectangle().fill(MAColor.divider).frame(height: 0.5)
        CredentialRow(
            credential: Credential(
                serviceName: "카카오", username: "kakao_id", passwordRef: "ref2",
                colorHex: "#FEE500"
            ),
            onToggleFavorite: {}
        )
    }
    .background(MAColor.card)
    .clipShape(RoundedRectangle(cornerRadius: MARadius.card, style: .continuous))
    .padding()
    .background(MAColor.appBackground)
}
