import SwiftData
import XCTest
@testable import myArchive

/// AddEditViewModel.save(context:) 영속화 검증 — 방식 B(PRD 9 / F-1).
/// 인메모리 ModelContainer로 SwiftData 메타 저장을 격리 검증한다.
/// 시크릿(비밀번호·커스텀 값)은 실기기 Keychain에 실제로 써지므로,
/// tearDown에서 이 테스트가 만든 모든 참조 키를 정리한다(잔여 금지).
final class PersistenceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Credential.self, CustomField.self,
            configurations: config
        )
        context = container.mainContext
    }

    override func tearDown() {
        // 이 테스트가 Keychain에 남긴 시크릿을 모두 정리(방식 B 부수효과 격리).
        if let creds = try? context.fetch(FetchDescriptor<Credential>()) {
            for cred in creds {
                KeychainService.delete(cred.passwordRef)
                for field in cred.customFields {
                    KeychainService.delete(field.valueRef)
                }
            }
        }
        context = nil
        container = nil
    }

    private func fetchCredentials() throws -> [Credential] {
        try context.fetch(FetchDescriptor<Credential>())
    }

    // MARK: 1. 신규 저장 — createdAt≈현재, updatedAt == nil

    func testNewSaveSetsCreatedAtAndNilUpdatedAt() throws {
        let vm = AddEditViewModel()
        vm.serviceName = "Apple"
        vm.username = "a@example.com"
        vm.password = "secret-pw"

        vm.save(context: context)

        let creds = try fetchCredentials()
        XCTAssertEqual(creds.count, 1)
        let cred = try XCTUnwrap(creds.first)
        XCTAssertEqual(cred.serviceName, "Apple")
        XCTAssertLessThan(Date().timeIntervalSince(cred.createdAt), 5)
        XCTAssertNil(cred.updatedAt)
    }

    // MARK: 2. 편집 저장 — updatedAt != nil, createdAt 불변

    func testEditSaveTouchesUpdatedAtButKeepsCreatedAt() throws {
        let originalCreatedAt = Date(timeIntervalSince1970: 1_600_000_000)
        let existing = Credential(
            serviceName: "Google",
            username: "g@example.com",
            passwordRef: KeychainService.passwordRef(for: UUID()),
            createdAt: originalCreatedAt
        )
        context.insert(existing)
        try context.save()

        let vm = AddEditViewModel(editing: existing)
        vm.username = "changed@example.com"
        vm.save(context: context)

        let cred = try XCTUnwrap(try fetchCredentials().first)
        XCTAssertEqual(cred.username, "changed@example.com")
        XCTAssertNotNil(cred.updatedAt)
        XCTAssertEqual(cred.createdAt, originalCreatedAt)
    }

    // MARK: 3. colorHex 폴백 — 빈 값이면 서비스명 해시, 지정 값은 유지

    func testColorHexFallbackWhenEmpty() throws {
        let vm = AddEditViewModel()
        vm.serviceName = "Netflix"
        vm.username = "n@example.com"
        vm.password = "pw"
        // colorHex는 기본 "" → 폴백 경로.

        vm.save(context: context)

        let cred = try XCTUnwrap(try fetchCredentials().first)
        XCTAssertEqual(cred.colorHex, MAAvatarPalette.fallbackHex(for: "Netflix"))
    }

    func testColorHexKeptWhenSpecified() throws {
        let vm = AddEditViewModel()
        vm.serviceName = "Steam"
        vm.username = "s@example.com"
        vm.password = "pw"
        vm.colorHex = "#1B2838"

        vm.save(context: context)

        let cred = try XCTUnwrap(try fetchCredentials().first)
        XCTAssertEqual(cred.colorHex, "#1B2838")
    }

    // MARK: 4. 방식 B 준수 — 평문 시크릿은 메타에 없고 참조 키만 보유

    func testMethodBStoresRefsNotPlaintext() throws {
        let plaintextPassword = "super-secret-1234"
        let plaintextValue = "custom-secret-value"
        let vm = AddEditViewModel()
        vm.serviceName = "Bank"
        vm.username = "b@example.com"
        vm.password = plaintextPassword
        vm.fields = [AddEditViewModel.DraftField(label: "PIN", value: plaintextValue)]

        vm.save(context: context)

        let cred = try XCTUnwrap(try fetchCredentials().first)

        // passwordRef는 "pw_" 접두 참조 키일 뿐, 평문이 아니다.
        XCTAssertTrue(cred.passwordRef.hasPrefix("pw_"))
        XCTAssertNotEqual(cred.passwordRef, plaintextPassword)

        // 커스텀 필드도 "cf_" 접두 참조 키만 메타에 보유.
        let field = try XCTUnwrap(cred.customFields.first)
        XCTAssertTrue(field.valueRef.hasPrefix("cf_"))
        XCTAssertNotEqual(field.valueRef, plaintextValue)

        // 메타 어디에도 평문이 스며들지 않았는지 교차 확인.
        let metaStrings = [
            cred.serviceName, cred.username, cred.passwordRef,
            cred.colorHex, cred.memo ?? "", cred.urlString ?? "",
            field.label, field.valueRef
        ]
        for meta in metaStrings {
            XCTAssertFalse(meta.contains(plaintextPassword))
            XCTAssertFalse(meta.contains(plaintextValue))
        }
    }

    // MARK: 5. 커스텀 필드 sortOrder 0/1/2 유지 + 빈 초안 폐기

    func testCustomFieldsSortOrderAndDiscardEmpty() throws {
        let vm = AddEditViewModel()
        vm.serviceName = "Discord"
        vm.username = "d@example.com"
        vm.password = "pw"
        vm.fields = [
            AddEditViewModel.DraftField(label: "First", value: "v1"),
            AddEditViewModel.DraftField(label: "Second", value: "v2"),
            AddEditViewModel.DraftField(label: "Third", value: "v3"),
            // 라벨·값 둘 다 빈 초안 → 폐기 대상.
            AddEditViewModel.DraftField(label: "", value: "")
        ]

        vm.save(context: context)

        let cred = try XCTUnwrap(try fetchCredentials().first)
        let sorted = cred.customFields.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(sorted.count, 3) // 빈 초안 폐기 확인.
        XCTAssertEqual(sorted.map(\.sortOrder), [0, 1, 2])
        XCTAssertEqual(sorted.map(\.label), ["First", "Second", "Third"])
    }
}
