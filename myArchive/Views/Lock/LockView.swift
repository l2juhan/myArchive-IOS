import SwiftUI

/// 잠금 화면 — 앱 잠금 ON일 때만(Design.md 2.1 / 3.9).
struct LockView: View {
    @Binding var isUnlocked: Bool
    @State private var authing = false
    @State private var pulsing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FBFCFC"), Color(hex: "#E7EEEE")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("잠겨 있어요")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MAColor.captionAlt)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 12) {
                    BrandIconView()

                    Text("마이아카이브")
                        .font(MAType.brand)
                        .foregroundStyle(MAColor.ink)

                    Text(authing ? "인증 중…" : "Face ID로 잠금 해제")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MAColor.secondary)
                }

                Spacer().frame(height: 32)

                faceIDTrigger

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        Task { await unlock() }
                    } label: {
                        Text("Face ID로 잠금 해제")
                            .font(MAType.barButtonStrong)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(MAColor.primary, in: RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                    }

                    Button("암호로 잠금 해제") {
                        Task { await unlock() }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MAColor.interactiveText)
                }
                .padding(.horizontal, MASpacing.screenHorizontal)
                .padding(.bottom, 40)
            }
        }
        .task { await unlock() } // 진입 시 자동 인증 시도
    }

    private var faceIDTrigger: some View {
        ZStack {
            Circle()
                .stroke(MAColor.primary, lineWidth: 2)
                .scaleEffect(pulsing ? 1.3 : 1.0)
                .opacity(pulsing ? 0 : 0.6)
                .animation(MAMotion.pulse, value: pulsing)

            Button {
                Task { await unlock() }
            } label: {
                Image(systemName: "faceid")
                    .font(.system(size: 32))
                    .foregroundStyle(MAColor.primary)
                    .frame(width: 88, height: 88)
                    .background(MAColor.faceIDButtonBG, in: Circle())
            }
        }
        .frame(width: 88, height: 88)
        .onAppear { pulsing = true }
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

/// 앱 아이콘을 SwiftUI로 재현 — 에셋 추가 없이 잠금 화면 브랜드 마크로 사용.
private struct BrandIconView: View {
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

#Preview("잠금") {
    LockView(isUnlocked: .constant(false))
}
