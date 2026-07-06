import SwiftUI

/// 루트 — 잠금 게이트(Design.md 3.1).
/// 앱 잠금이 켜져 있으면 잠금 화면을 먼저 보여주고, 인증 후 메인 목록으로 진입한다.
/// 잠금이 꺼져 있으면(기본값) 바로 목록으로 진입(PRD 10.2).
struct RootView: View {
    @AppStorage(SettingsKey.isAppLockEnabled) private var isAppLockEnabled = false
    @Environment(AppLockController.self) private var lockController
    @Environment(ScreenCaptureMonitor.self) private var captureMonitor
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPrivacyShieldVisible = false
    @State private var isScreenshotWarningVisible = false

    var body: some View {
        @Bindable var lockController = lockController
        return Group {
            if isAppLockEnabled, !lockController.isUnlocked {
                LockView(isUnlocked: $lockController.isUnlocked)
            } else {
                CredentialListView()
            }
        }
        .background(MAColor.appBackground.ignoresSafeArea())
        .overlay {
            // 앱 스위처 스냅샷(F-10)과 화면 녹화·미러링(F-11) 어느 쪽이든 민감 화면을 덮는다.
            // 캡처는 스냅샷 타이밍이라 등장 애니메이션 없이 즉시 가려야 안전하다(PrivacyShieldView가 그러함).
            if isPrivacyShieldVisible || captureMonitor.isCaptured {
                PrivacyShieldView()
            }
        }
        // 스크린샷은 찍힌 뒤에만 통지된다 — 카운터 증가를 사후 경고 토스트로 알린다(F-11).
        .maToast(
            isPresented: $isScreenshotWarningVisible,
            title: "스크린샷이 감지되었어요",
            subtitle: "민감 정보가 캡처됐을 수 있어요"
        )
        .onChange(of: captureMonitor.screenshotCount) { _, _ in
            isScreenshotWarningVisible = true
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .inactive:
                // 앱 스위처 스냅샷이 찍히는 시점 — 잠금 해제된 상태에서만 가림막을 올린다.
                // 여기서 lock()을 부르지 않는 이유: Face ID 시트가 .inactive를 유발해 인증 루프가 생긴다.
                if lockController.isUnlocked {
                    isPrivacyShieldVisible = true
                }
            case .active:
                isPrivacyShieldVisible = false
            case .background:
                if isAppLockEnabled {
                    lockController.lock()
                }
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppLockController())
        .environment(ScreenCaptureMonitor())
}
