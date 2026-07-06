import SwiftUI

/// 하단 자동 해제 토스트 — Design.md 2.6.
/// 다크 카드 위 초록 성공 배지 + 제목/서브텍스트. 2.4초 후 스스로 사라진다.
/// 표시만 담당하며, 트리거·문구는 호출부가 바인딩·인자로 넘긴다.
struct MAToast: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MAColor.success)
                    .frame(width: 26, height: 26)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MAType.toastTitle)
                    .foregroundStyle(.white)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(MAType.toastSub)
                        .foregroundStyle(MAColor.toastSub)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: MARadius.toast, style: .continuous)
                .fill(MAColor.toastSurface)
        )
        .shadow(color: .black.opacity(0.28), radius: 16, x: 0, y: 12)
    }
}

/// 토스트 오버레이 모디파이어 — 바인딩이 true가 되면 등장 후 2.4초 뒤 자동 해제.
private struct MAToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let subtitle: String

    /// 자동 해제 시간 — Design.md 2.6.
    private let duration: TimeInterval = 2.4

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if isPresented {
                MAToast(title: title, subtitle: subtitle)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 48)
                    .transition(
                        .move(edge: .bottom).combined(with: .opacity)
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(MAMotion.toast) { isPresented = false }
                        }
                    }
            }
        }
        .animation(MAMotion.toast, value: isPresented)
    }
}

extension View {
    /// 하단 성공 토스트를 붙인다. `isPresented`를 true로 만들면 등장 후 자동 해제된다.
    func maToast(
        isPresented: Binding<Bool>,
        title: String,
        subtitle: String = ""
    ) -> some View {
        modifier(
            MAToastModifier(isPresented: isPresented, title: title, subtitle: subtitle)
        )
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var showToast = false

        var body: some View {
            VStack {
                Spacer()
                Button("토스트 띄우기") {
                    withAnimation(MAMotion.toast) { showToast = true }
                }
                .font(MAType.barButtonStrong)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MAColor.appBackground)
            .maToast(
                isPresented: $showToast,
                title: "복사했어요",
                subtitle: "60초 후 클립보드에서 지워져요"
            )
        }
    }
    return PreviewHost()
}
