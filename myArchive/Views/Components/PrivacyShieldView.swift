import SwiftUI

/// 앱 스위처 가림막 — 잠금 ON 상태에서 백그라운드 전이 시 스냅샷에 민감 정보가 찍히지 않도록 덮는다(PRD 7.4 / F-10).
/// 스냅샷 타이밍에 맞춰 즉시 등장해야 하므로 애니메이션을 두지 않는다.
struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ShieldBrandIconView()

                Text("마이아카이브")
                    .font(MAType.brand)
                    .foregroundStyle(MAColor.ink)
            }
        }
    }
}

/// 앱 아이콘을 SwiftUI로 재현 — LockView의 BrandIconView와 분리 유지를 위해 여기 별도 정의.
private struct ShieldBrandIconView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#6768CE"), Color(hex: "#36368C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 84, height: 84)
            .overlay(
                Image(systemName: "key.horizontal.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white)
            )
    }
}

#Preview("가림막") {
    PrivacyShieldView()
}
