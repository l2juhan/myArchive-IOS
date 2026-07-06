import XCTest
@testable import myArchive

/// DetailViewModel의 순수 로직(복사 토스트 문구) + ClipboardExpiry 매핑 검증.
/// 클립보드 실동작·타이머는 실기기 몫이라 여기서는 값 계약만 본다.
final class DetailViewModelTests: XCTestCase {
    /// copyToastSubtitle: "N초 후 자동 삭제" 문자열 생성.
    func testCopyToastSubtitle() {
        XCTAssertEqual(DetailViewModel.copyToastSubtitle(seconds: 30), "30초 후 자동 삭제")
        XCTAssertEqual(DetailViewModel.copyToastSubtitle(seconds: 60), "60초 후 자동 삭제")
        XCTAssertEqual(DetailViewModel.copyToastSubtitle(seconds: 120), "120초 후 자동 삭제")
    }

    /// ClipboardExpiry rawValue가 30/60/120초로 매핑되는지.
    func testClipboardExpiryMapping() {
        XCTAssertEqual(ClipboardExpiry.thirty.rawValue, 30)
        XCTAssertEqual(ClipboardExpiry.sixty.rawValue, 60)
        XCTAssertEqual(ClipboardExpiry.oneTwenty.rawValue, 120)
    }

    /// ClipboardExpiry.label이 "N초" 표기인지(세그먼트 표시용).
    func testClipboardExpiryLabel() {
        XCTAssertEqual(ClipboardExpiry.thirty.label, "30초")
        XCTAssertEqual(ClipboardExpiry.sixty.label, "60초")
        XCTAssertEqual(ClipboardExpiry.oneTwenty.label, "120초")
    }
}
