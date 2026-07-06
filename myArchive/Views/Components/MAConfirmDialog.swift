import SwiftUI

/// 삭제 확인 모달 — Design.md 2.6.
/// 반투명 딤 위 중앙 흰 카드. 딤은 페이드, 카드는 팝(scale .93→1)으로 등장한다.
/// 표시·애니메이션만 담당하고, 실제 삭제는 `onConfirm` 콜백으로 호출부에 위임한다.
struct MAConfirmDialog: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { dismiss() }

                card
                    .transition(.scale(scale: 0.93).combined(with: .opacity))
            }
        }
        .animation(MAMotion.modal, value: isPresented)
    }

    private var card: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MAColor.ink)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MAColor.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()
                .overlay(MAColor.divider)

            HStack(spacing: 0) {
                Button(action: dismiss) {
                    Text("취소")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MAColor.interactiveText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }

                Divider()
                    .overlay(MAColor.divider)
                    .frame(height: 52)

                Button(action: confirm) {
                    Text("삭제")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MAColor.destructive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: MARadius.modal, style: .continuous)
                .fill(MAColor.card)
        )
        .shadow(color: .black.opacity(0.32), radius: 30, x: 0, y: 24)
        .padding(.horizontal, 40)
    }

    private func dismiss() {
        withAnimation(MAMotion.modal) { isPresented = false }
    }

    private func confirm() {
        withAnimation(MAMotion.modal) { isPresented = false }
        onConfirm()
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var showDialog = false

        var body: some View {
            Button("삭제 모달 열기") {
                showDialog = true
            }
            .font(MAType.barButtonStrong)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MAColor.appBackground)
            .overlay {
                MAConfirmDialog(
                    isPresented: $showDialog,
                    title: "이 계정을 삭제할까요?",
                    message: "삭제하면 되돌릴 수 없어요.",
                    onConfirm: {}
                )
            }
        }
    }
    return PreviewHost()
}
