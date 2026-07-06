import Observation

/// 앱 잠금 상태를 화면 간 공유하는 컨트롤러(PRD 7.4).
/// RootView가 잠금 게이트로 관찰하고, SettingsView의 "지금 잠그기"가 lock()으로 재잠금한다.
@Observable
final class AppLockController {
    var isUnlocked: Bool = false

    func lock() {
        isUnlocked = false
    }
}
