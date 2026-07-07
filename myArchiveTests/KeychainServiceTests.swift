import XCTest
@testable import myArchive

/// KeychainService 저장/조회/삭제/키규칙 검증 — 방식 B 시크릿 저장소(PRD 7.2~7.3 / 9.3).
/// 라운드트립·갱신·삭제는 실제 Keychain을 건드리므로, 유닛 테스트 host에서 접근이 막히면
/// XCTSkip으로 실기기 확인에 넘긴다(CredentialStoreTests 패턴 재사용). 키 규칙은 순수 문자열
/// 조합이라 Keychain 접근 없이 항상 실행한다.
final class KeychainServiceTests: XCTestCase {
    /// 실패 시에도 Keychain에 잔여를 남기지 않도록 이 테스트가 건드린 키를 추적한다.
    private var touchedKeys: [String] = []

    override func setUp() {
        super.setUp()
        touchedKeys = []
    }

    override func tearDown() {
        for key in touchedKeys {
            KeychainService.delete(key)
        }
        touchedKeys = []
        super.tearDown()
    }

    /// 매 테스트마다 고유 키를 만들어 다른 케이스·잔여와 충돌하지 않게 한다.
    private func makeKey(_ prefix: String) -> String {
        let key = "\(prefix)_test_\(UUID().uuidString)"
        touchedKeys.append(key)
        return key
    }

    /// set이 host에서 막히면(권한 없음) 검증 불가 → skip으로 실기기에 넘긴다.
    private func setOrSkip(_ value: String, for key: String) throws {
        do {
            try KeychainService.set(value, for: key)
        } catch {
            throw XCTSkip("Keychain 접근 불가(test host) — 실기기 확인 필요: \(error)")
        }
    }

    // MARK: 1. set → get 라운드트립

    func testSetThenGetReturnsSameValue() throws {
        let key = makeKey("pw")
        try setOrSkip("plaintext-secret", for: key)
        XCTAssertEqual(KeychainService.get(key), "plaintext-secret")
    }

    // MARK: 2. 같은 키 재저장 → 갱신(중복 아님, 마지막 값)

    func testResaveUpdatesNotDuplicates() throws {
        let key = makeKey("pw")
        try setOrSkip("old-value", for: key)
        try setOrSkip("new-value", for: key)
        // SecItemUpdate 경로로 갱신되어 마지막 값만 남는다.
        XCTAssertEqual(KeychainService.get(key), "new-value")
    }

    // MARK: 3. delete 후 get → nil

    func testDeleteRemovesValue() throws {
        let key = makeKey("cf")
        try setOrSkip("to-be-deleted", for: key)
        XCTAssertTrue(KeychainService.delete(key))
        // 삭제 후에는 평문을 추측하지 말고 nil이어야 한다(PRD 13 정합성).
        XCTAssertNil(KeychainService.get(key))
    }

    // MARK: 4. 없는 키 delete → true(errSecItemNotFound도 성공 취급)

    func testDeleteMissingKeyReturnsTrue() {
        // 심지 않은 고유 키 삭제 — errSecItemNotFound를 성공으로 본다.
        let key = makeKey("pw")
        XCTAssertTrue(KeychainService.delete(key))
    }

    // MARK: 5. 키 규칙 — passwordRef/valueRef 접두사 (Keychain 접근 없음)

    func testPasswordRefUsesPwPrefix() throws {
        let id = try XCTUnwrap(UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
        XCTAssertEqual(KeychainService.passwordRef(for: id), "pw_\(id.uuidString)")
    }

    func testValueRefUsesCfPrefix() throws {
        let id = try XCTUnwrap(UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"))
        XCTAssertEqual(KeychainService.valueRef(for: id), "cf_\(id.uuidString)")
    }
}
