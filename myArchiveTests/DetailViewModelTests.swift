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

    // MARK: 마스킹 상태 전이 (reveal/resetReveal)

    /// 마스킹 없이 항상 성립하는 Credential 하나 — 시크릿은 Keychain에 심지 않는다.
    /// init의 KeychainService.get은 nil을 돌려줄 뿐 throw하지 않으므로 host 무관하게 동작.
    private func makeViewModel() -> DetailViewModel {
        let cred = Credential(
            serviceName: "Naver",
            username: "n@example.com",
            passwordRef: KeychainService.passwordRef(for: UUID())
        )
        return DetailViewModel(credential: cred)
    }

    /// reveal(id:) → revealedFields에 해당 id 포함(마스킹 해제).
    @MainActor
    func testRevealAddsFieldID() {
        let vm = makeViewModel()
        let id = UUID()

        vm.reveal(id: id)

        XCTAssertTrue(vm.revealedFields.contains(id))
        vm.resetReveal() // 22초 타이머 Task 정리
    }

    /// 이미 해제된 id에 reveal 재호출 → 여전히 포함(단방향, 토글 아님).
    @MainActor
    func testRevealIsIdempotentNotToggle() {
        let vm = makeViewModel()
        let id = UUID()

        vm.reveal(id: id)
        vm.reveal(id: id) // 같은 동작 재호출

        // 토글이라면 두 번째 호출에 마스킹으로 되돌아가야 하지만, 단방향이라 유지된다.
        XCTAssertTrue(vm.revealedFields.contains(id))
        XCTAssertEqual(vm.revealedFields.count, 1)
        vm.resetReveal()
    }

    /// resetReveal() → revealedFields 빈 집합(화면 이탈 재마스킹).
    @MainActor
    func testResetRevealClearsAll() {
        let vm = makeViewModel()
        vm.reveal(id: UUID())
        vm.reveal(id: UUID())

        vm.resetReveal()

        XCTAssertTrue(vm.revealedFields.isEmpty)
    }

    // MARK: 조회 실패 → .error 경로

    /// Keychain에 심지 않은 passwordRef를 가진 Credential → passwordLoadFailed →
    /// 비밀번호 행이 kind == .error. 그 .error item에 copy를 넘겨도 no-op(값 계약).
    func testPasswordLoadFailedProducesErrorRowAndCopyIsNoOp() {
        // 심지 않은 고유 참조 키 → init의 get이 nil → passwordLoadFailed=true(host 무관).
        let cred = Credential(
            serviceName: "Naver",
            username: "n@example.com",
            passwordRef: KeychainService.passwordRef(for: UUID())
        )
        let vm = DetailViewModel(credential: cred)

        let errorItem = try? XCTUnwrap(vm.fieldItems.first { $0.label == "비밀번호" })
        XCTAssertEqual(errorItem?.kind, .error)
        XCTAssertEqual(errorItem?.value, "") // .error는 값 없음

        // .error 항목 copy는 early-return이어야 한다 — 예외·크래시 없이 no-op.
        if let errorItem {
            vm.copy(item: errorItem, expirySec: 30)
        }
    }
}
