import Foundation
import SwiftData

/// 계정 삭제 정합성 프리미티브 — 방식 B(PRD 13).
/// SwiftData의 `.cascade`는 CustomField "메타"만 지우므로, 그 값이 사는
/// Keychain 시크릿(valueRef·passwordRef)은 고아로 남는다(keychain-schema.md).
/// 메타와 시크릿을 함께 정리해 정합성을 지킨다.
enum CredentialStore {
    /// 계정 삭제 — 메타(cascade)와 Keychain 시크릿을 함께 정리한다(PRD 13 정합성).
    static func delete(_ credential: Credential, from context: ModelContext) {
        // 1) 커스텀 필드 값 시크릿 정리 (순회 중 값만 읽으므로 삭제 안전).
        for field in credential.customFields {
            KeychainService.delete(field.valueRef)
        }
        // 2) 비밀번호 시크릿 정리.
        KeychainService.delete(credential.passwordRef)
        // 3) 메타 삭제 — CustomField 메타는 @Relationship(.cascade)가 함께 정리.
        context.delete(credential)
        // 4) 영속화.
        try? context.save()
    }
}
