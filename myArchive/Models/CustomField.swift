import Foundation
import SwiftData

/// 사용자 정의 필드 구조 — 방식 B(PRD 9.2).
/// 값 자체는 Keychain에, 이름·순서·참조 키는 SwiftData에 둔다.
@Model
final class CustomField {
    @Attribute(.unique) var id: UUID
    var label: String // 예: "2차 비밀번호"
    var valueRef: String // 실제 값의 Keychain 조회 키
    var sortOrder: Int // 상세 화면 내 표시 순서
    var credential: Credential?

    init(
        id: UUID = UUID(),
        label: String,
        valueRef: String,
        sortOrder: Int,
        credential: Credential? = nil
    ) {
        self.id = id
        self.label = label
        self.valueRef = valueRef
        self.sortOrder = sortOrder
        self.credential = credential
    }
}
