import SwiftData
import XCTest
@testable import myArchive

/// CredentialStore.delete(_:from:) 삭제 정합성 검증 — 방식 B(PRD 13).
/// SwiftData cascade가 메타를, CredentialStore가 Keychain 시크릿을 함께 정리하는지 본다.
/// 인메모리 ModelContainer로 메타를, 실기기 Keychain으로 시크릿을 검증한다.
final class CredentialStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    /// 실패 시 잔여 정리를 위해 이 테스트가 만든 Keychain 키를 추적한다.
    private var touchedKeys: [String] = []

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Credential.self, CustomField.self,
            configurations: config
        )
        context = container.mainContext
        touchedKeys = []
    }

    override func tearDown() {
        // 삭제 테스트가 도중 실패해도 Keychain 잔여를 남기지 않는다.
        for key in touchedKeys {
            KeychainService.delete(key)
        }
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

    // MARK: 1. cascade 삭제 — 메타 Credential·CustomField 모두 0건

    func testDeleteCascadesMetadata() throws {
        let vm = AddEditViewModel()
        vm.serviceName = "Kakao"
        vm.username = "k@example.com"
        vm.password = "pw"
        vm.fields = [
            AddEditViewModel.DraftField(label: "PIN", value: "1234"),
            AddEditViewModel.DraftField(label: "OTP", value: "5678")
        ]
        vm.save(context: context)

        let cred = try XCTUnwrap(try context.fetch(FetchDescriptor<Credential>()).first)
        touchedKeys.append(cred.passwordRef)
        touchedKeys.append(contentsOf: cred.customFields.map(\.valueRef))

        CredentialStore.delete(cred, from: context)

        XCTAssertEqual(try context.fetch(FetchDescriptor<Credential>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<CustomField>()).count, 0)
    }

    // MARK: 2. Keychain 정리 — passwordRef/valueRef 조회가 nil

    func testDeleteRemovesKeychainSecrets() throws {
        // 고유 UUID로 참조 키를 만들어 실제 Keychain에 시크릿을 심는다.
        let credentialID = UUID()
        let fieldID = UUID()
        let passwordRef = KeychainService.passwordRef(for: credentialID)
        let valueRef = KeychainService.valueRef(for: fieldID)
        touchedKeys.append(passwordRef)
        touchedKeys.append(valueRef)

        // Keychain 접근이 유닛 테스트 host에서 막히면 이 케이스는 검증 불가 → skip.
        do {
            try KeychainService.set("plaintext-password", for: passwordRef)
            try KeychainService.set("plaintext-value", for: valueRef)
        } catch {
            throw XCTSkip("Keychain 접근 불가(테스트 host) — 실기기에서 확인 필요: \(error)")
        }

        // 사전 조건: 실제로 심겼는지 확인.
        XCTAssertEqual(KeychainService.get(passwordRef), "plaintext-password")
        XCTAssertEqual(KeychainService.get(valueRef), "plaintext-value")

        let field = CustomField(id: fieldID, label: "PIN", valueRef: valueRef, sortOrder: 0)
        let cred = Credential(
            id: credentialID,
            serviceName: "Naver",
            username: "n@example.com",
            passwordRef: passwordRef,
            customFields: [field]
        )
        context.insert(cred)
        try context.save()

        CredentialStore.delete(cred, from: context)

        // 시크릿이 함께 정리되어 조회가 nil이어야 한다(PRD 13 정합성).
        XCTAssertNil(KeychainService.get(passwordRef))
        XCTAssertNil(KeychainService.get(valueRef))
    }
}
