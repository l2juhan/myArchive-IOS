import SwiftUI

/// 상세 화면 — 시크릿 블러·터치 해제(F-3) + 필드별 복사(F-4). Design.md 2.3 / 3.5 / 3.6.
/// 현재는 골격(필드 카드·블러·복사 버튼·삭제 모달은 M3/M5에서 마감).
struct CredentialDetailView: View {
    let credential: Credential

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AvatarView(initial: credential.initial, colorHex: credential.colorHex, size: 62)
                Text(credential.serviceName)
                    .font(MAType.detailTitle)
                    .foregroundStyle(MAColor.ink)
                Text(RelativeTime.subtitle(for: credential))
                    .font(MAType.rowSubtitle)
                    .foregroundStyle(MAColor.secondaryAlt)

                // TODO(M3/M5): 시크릿 필드 카드(아이디·비밀번호·커스텀) 블러+터치 해제, 필드별 복사, URL·메모, 삭제
                Text("필드 카드 — M3/M5에서 구현")
                    .font(MAType.caption)
                    .foregroundStyle(MAColor.caption)
                    .padding(.top, 24)
            }
            .padding(MASpacing.screenHorizontal)
        }
        .background(MAColor.appBackground.ignoresSafeArea())
        .navigationTitle(credential.serviceName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
