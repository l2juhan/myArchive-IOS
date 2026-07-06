import Observation
import UIKit

/// 화면 캡처(녹화·미러링·AirPlay)와 스크린샷을 감시하는 컨트롤러(PRD 7.7 · F-11).
/// RootView가 관찰해 캡처 중에는 화면을 가리고, 스크린샷이 찍히면 사후 경고 토스트를 띄운다.
///
/// iOS 한계: 스크린샷을 **원천 차단하는 공개 API는 없다**. 여기서 하는 건
/// (1) 화면 캡처 중 여부(`UIScreen.isCaptured`)를 감지해 가리는 사전 대응과
/// (2) 스크린샷은 찍힌 **뒤**에만 알 수 있어(`userDidTakeScreenshotNotification`) 사후 경고뿐이다.
/// PRD 7.7의 보안 입력 레이어 트릭(비공식 기법)은 스코프에서 제외한다.
@Observable
final class ScreenCaptureMonitor {
    /// 화면 녹화·미러링·AirPlay 등으로 화면이 캡처되는 중인지. true면 UI가 민감 화면을 가린다.
    private(set) var isCaptured: Bool
    /// 스크린샷이 찍힌 횟수. 증가할 때마다 UI가 사후 경고 토스트를 띄운다(사전 차단은 iOS 한계상 불가).
    private(set) var screenshotCount: Int

    /// NotificationCenter 옵저버 토큰. deinit에서 해제해 누수·중복 등록을 막는다.
    private var observers: [NSObjectProtocol] = []

    init() {
        isCaptured = UIScreen.main.isCaptured
        screenshotCount = 0

        let center = NotificationCenter.default

        // 녹화·미러링 시작/종료로 캡처 상태가 바뀔 때마다 갱신한다.
        observers.append(
            center.addObserver(
                forName: UIScreen.capturedDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.isCaptured = UIScreen.main.isCaptured
            }
        )

        // 스크린샷은 사후 통지만 온다 — 카운터를 올려 UI가 경고 토스트를 띄우게 한다.
        observers.append(
            center.addObserver(
                forName: UIApplication.userDidTakeScreenshotNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.screenshotCount += 1
            }
        )
    }

    deinit {
        let center = NotificationCenter.default
        observers.forEach(center.removeObserver)
    }
}
