import SwiftUI

/// 루트 — 잠금 게이트(Design.md 3.1).
/// 앱 잠금이 켜져 있으면 잠금 화면을 먼저 보여주고, 인증 후 메인 목록으로 진입한다.
/// 잠금이 꺼져 있으면(기본값) 바로 목록으로 진입(PRD 10.2).
struct RootView: View {
    @AppStorage(SettingsKey.isAppLockEnabled) private var isAppLockEnabled = false
    @Environment(AppLockController.self) private var lockController
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPrivacyShieldVisible = false

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
            if isPrivacyShieldVisible {
                PrivacyShieldView()
            }
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
}
