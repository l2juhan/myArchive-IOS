import SwiftData
import SwiftUI

/// 앱 진입점. SwiftData 컨테이너(메타데이터)를 구성한다 — 방식 B(PRD 7.2).
@main
struct MyArchiveApp: App {
    let container: ModelContainer
    private let lockController = AppLockController()
    private let captureMonitor = ScreenCaptureMonitor()

    init() {
        do {
            container = try ModelContainer(for: Credential.self, CustomField.self)
        } catch {
            fatalError("SwiftData ModelContainer 생성 실패: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(lockController)
                .environment(captureMonitor)
        }
        .modelContainer(container)
    }
}
