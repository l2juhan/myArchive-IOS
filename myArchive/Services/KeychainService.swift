import Foundation
import Security

/// 시크릿 저장소 — 방식 B(PRD 7.2~7.3).
/// 비밀번호·커스텀 필드 값을 Keychain에 저장하고, SwiftData에는 조회 키만 둔다.
/// 접근성은 kSecAttrAccessibleWhenUnlocked — 기기가 잠금 해제된 상태에서만 접근 가능(PRD 7.3).
enum KeychainService {
    static let service = "com.l2juhan.myArchive.secrets"

    enum KeychainError: Error {
        case unexpectedStatus(OSStatus)
        case encodingFailed
    }

    /// 시크릿 저장(없으면 추가, 있으면 갱신).
    static func set(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.encodingFailed }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(addStatus) }
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// 시크릿 조회 — 표시 시점에만 호출(PRD 6.1 인메모리 검색 + 표시 시 조회).
    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 시크릿 삭제 — 계정/필드 삭제 시 메타와 함께 정리(PRD 13 정합성).
    @discardableResult
    static func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// 참조 키 생성 헬퍼 — 계정/필드 id 기반(PRD 9.3).
    static func passwordRef(for credentialID: UUID) -> String {
        "pw_\(credentialID.uuidString)"
    }

    static func valueRef(for fieldID: UUID) -> String {
        "cf_\(fieldID.uuidString)"
    }
}
