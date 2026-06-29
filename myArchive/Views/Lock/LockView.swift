import SwiftUI

/// 잠금 화면 — 앱 잠금 ON일 때만(Design.md 2.1 / 3.9).
/// M4에서 펄스 링·아이콘 등 시각 디테일을 마감한다. 현재는 동작 골격.
struct LockView: View {
    @Binding var isUnlocked: Bool
    @State private var authing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FBFCFC"), Color(hex: "#E7EEEE")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("마이아카이브")
                    .font(MAType.brand)
                    .foregroundStyle(MAColor.ink)

                Text(authing ? "인증 중…" : "Face ID로 잠금 해제")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MAColor.secondary)

                Button {
                    Task { await unlock() }
                } label: {
                    Text("Face ID로 잠금 해제")
                        .font(MAType.barButtonStrong)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(MAColor.primary, in: RoundedRectangle(cornerRadius: MARadius.button))
                }
                .padding(.horizontal, MASpacing.screenHorizontal)
                .padding(.top, 24)
            }
        }
        .task { await unlock() } // 진입 시 자동 인증 시도
    }

    private func unlock() async {
        guard !authing else { return }
        authing = true
        defer { authing = false }
        if await AuthService.authenticate() {
            isUnlocked = true
        }
    }
}

#Preview {
    LockView(isUnlocked: .constant(false))
}
