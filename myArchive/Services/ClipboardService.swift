import UIKit

/// 클립보드 보호 — F-4 / F-8 (PRD 7.6).
/// 필드별 개별 복사 + 만료 시간 설정으로 일정 시간 뒤 자동 제거.
enum ClipboardService {
    /// 값을 복사하고 만료 시간을 설정한다.
    static func copy(_ value: String, expiresInSeconds seconds: Int) {
        UIPasteboard.general.setItems(
            [[UIPasteboard.typeAutomatic: value]],
            options: [
                .expirationDate: Date().addingTimeInterval(TimeInterval(seconds))
            ]
        )
    }
}
