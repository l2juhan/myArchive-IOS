import XCTest
@testable import myArchive

/// RelativeTime.phrase(from:now:) / subtitle(for:now:) 경계값 검증.
/// now를 고정 주입해 시계에 의존하지 않는다.
final class RelativeTimeTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func ago(_ seconds: TimeInterval) -> Date {
        now.addingTimeInterval(-seconds)
    }

    /// <1분 → "방금 전"
    func testJustNow() {
        XCTAssertEqual(RelativeTime.phrase(from: now, now: now), "방금 전")
        XCTAssertEqual(RelativeTime.phrase(from: ago(59), now: now), "방금 전")
        // 미래 시각도 음수 클램프로 "방금 전".
        XCTAssertEqual(RelativeTime.phrase(from: now.addingTimeInterval(100), now: now), "방금 전")
    }

    /// 1~59분 → "N분 전"
    func testMinutes() {
        XCTAssertEqual(RelativeTime.phrase(from: ago(60), now: now), "1분 전")
        XCTAssertEqual(RelativeTime.phrase(from: ago(59 * 60), now: now), "59분 전")
    }

    /// 1~23시간 → "N시간 전"
    func testHours() {
        XCTAssertEqual(RelativeTime.phrase(from: ago(60 * 60), now: now), "1시간 전")
        XCTAssertEqual(RelativeTime.phrase(from: ago(23 * 60 * 60), now: now), "23시간 전")
    }

    /// 1~29일 → "N일 전"
    func testDays() {
        XCTAssertEqual(RelativeTime.phrase(from: ago(24 * 60 * 60), now: now), "1일 전")
        XCTAssertEqual(RelativeTime.phrase(from: ago(29 * 24 * 60 * 60), now: now), "29일 전")
    }

    /// 30일 이상 → "N주 전" (days / 7).
    func testWeeks() {
        // 30일 → 30/7 = 4주 전.
        XCTAssertEqual(RelativeTime.phrase(from: ago(30 * 24 * 60 * 60), now: now), "4주 전")
        // 56일 → 56/7 = 8주 전.
        XCTAssertEqual(RelativeTime.phrase(from: ago(56 * 24 * 60 * 60), now: now), "8주 전")
    }

    // subtitle: wasEdited(updatedAt 유무)에 따라 "수정"/"생성" 접미사.
    func testSubtitleSuffix() {
        let created = Credential(
            serviceName: "Apple",
            username: "a@example.com",
            passwordRef: "pw_a",
            createdAt: ago(120)
        )
        XCTAssertEqual(RelativeTime.subtitle(for: created, now: now), "2분 전 생성")

        let edited = Credential(
            serviceName: "Google",
            username: "g@example.com",
            passwordRef: "pw_g",
            createdAt: ago(10000),
            updatedAt: ago(120)
        )
        // activityDate가 updatedAt(120초 전)이므로 "2분 전 수정".
        XCTAssertEqual(RelativeTime.subtitle(for: edited, now: now), "2분 전 수정")
    }
}
