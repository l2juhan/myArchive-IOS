import SwiftUI

/// 루트 — 잠금 게이트(Design.md 3.1).
/// 앱 잠금이 켜져 있으면 잠금 화면을 먼저 보여주고, 인증 후 메인 목록으로 진입한다.
/// 잠금이 꺼져 있으면(기본값) 바로 목록으로 진입(PRD 10.2).
struct RootView: View {
    @AppStorage(SettingsKey.isAppLockEnabled) private var isAppLockEnabled = false
    @Environment(AppLockController.self) private var lockController

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
    }
}

#Preview {
    RootView()
        .environment(AppLockController())
}
