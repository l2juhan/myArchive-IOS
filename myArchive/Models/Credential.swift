import Foundation
import SwiftData

/// 계정 메타데이터 — 방식 B(PRD 9.1).
/// 시크릿(비밀번호·커스텀 값)은 여기 저장하지 않고 Keychain 참조 키만 보관한다.
@Model
final class Credential {
    @Attribute(.unique) var id: UUID
    var serviceName: String // 검색 대상
    var username: String // 검색 대상, 화면에서는 마스킹
    var passwordRef: String // 비밀번호의 Keychain 조회 키
    var memo: String?
    var urlString: String?
    var colorHex: String // F-15 아바타 색 (미지정 시 서비스명 해시 폴백)
    var isFavorite: Bool // 정렬 1순위
    var createdAt: Date // 수정 이력 없을 때 표시·정렬 기준
    var updatedAt: Date? // 있을 때 표시·정렬 기준

    @Relationship(deleteRule: .cascade, inverse: \CustomField.credential)
    var customFields: [CustomField]

    init(
        id: UUID = UUID(),
        serviceName: String,
        username: String,
        passwordRef: String,
        memo: String? = nil,
        urlString: String? = nil,
        colorHex: String = MAAvatarPalette.defaultHex,
        isFavorite: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        customFields: [CustomField] = []
    ) {
        self.id = id
        self.serviceName = serviceName
        self.username = username
        self.passwordRef = passwordRef
        self.memo = memo
        self.urlString = urlString
        self.colorHex = colorHex
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.customFields = customFields
    }

    /// 표시·정렬에 쓰는 활동 시각 (updatedAt 우선, 없으면 createdAt). PRD 9.4 / Design.md 3.3.
    var activityDate: Date { updatedAt ?? createdAt }

    /// 수정 이력 유무 — 보조 텍스트 "수정/생성" 분기에 사용. Design.md 3.4.
    var wasEdited: Bool { updatedAt != nil }

    /// 아바타 이니셜 (서비스명 첫 글자).
    var initial: String { String(serviceName.prefix(1)).uppercased() }
}
