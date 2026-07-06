import Foundation
import SwiftData

/// 상세 화면 ViewModel — 방식 B(PRD 6.1 / 9). 시크릿은 SwiftData에 없고,
/// 표시 시점에만 Keychain에서 조회해 메모리에 캐시한다. 값 처리는 여기로 모은다.
@Observable
final class DetailViewModel {
    // MARK: - 내부 모델

    enum FieldKind {
        case secret // blur 5px + 눈 힌트 아이콘
        case link // interactiveText 링크색, 블러 없음
        case plain // 일반 본문, 블러 없음
    }

    struct FieldItem: Identifiable {
        let id: UUID
        let label: String
        let value: String // 표시할 값 (빈 값이면 행 생략)
        let kind: FieldKind
    }

    // MARK: - 노출 상태

    let credential: Credential
    var isFavorite: Bool // MAFavoriteChip 바인딩용

    /// 필드 순서: 아이디 → 비밀번호 → 커스텀(sortOrder) → URL → 메모.
    /// 빈 값 행은 포함하지 않는다.
    var fieldItems: [FieldItem] { buildFieldItems() }

    // MARK: - 초기화 (표시 시점 시크릿 조회, PRD 6.1)

    init(credential: Credential) {
        self.credential = credential
        isFavorite = credential.isFavorite
        // 비밀번호 조회
        password = KeychainService.get(credential.passwordRef) ?? ""
        // 커스텀 필드 값 조회
        var vals: [UUID: String] = [:]
        for field in credential.customFields {
            vals[field.id] = KeychainService.get(field.valueRef) ?? ""
        }
        customValues = vals
    }

    // MARK: - 액션

    /// 계정 삭제 — CredentialStore.delete 위임 후 dismiss는 호출부가 처리.
    func delete(context: ModelContext) {
        CredentialStore.delete(credential, from: context)
    }

    /// 즐겨찾기 변경 저장 (MAFavoriteChip 탭 후 호출).
    func saveFavorite(context: ModelContext) {
        credential.isFavorite = isFavorite
        try? context.save()
    }

    // MARK: - Private

    @ObservationIgnored private var password: String
    @ObservationIgnored private var customValues: [UUID: String] = [:]

    // 고정 행 id — 매 호출마다 새 UUID를 만들면 List 갱신 시 깜빡이므로 상수로 고정.
    private static let usernameRowID = UUID()
    private static let passwordRowID = UUID()
    private static let urlRowID = UUID()
    private static let memoRowID = UUID()

    private func buildFieldItems() -> [FieldItem] {
        var items: [FieldItem] = []

        // 아이디
        if !credential.username.isEmpty {
            items.append(FieldItem(id: Self.usernameRowID, label: "아이디", value: credential.username, kind: .secret))
        }

        // 비밀번호
        if !password.isEmpty {
            items.append(FieldItem(id: Self.passwordRowID, label: "비밀번호", value: password, kind: .secret))
        }

        // 커스텀 필드 (sortOrder 순)
        for field in credential.customFields.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let val = customValues[field.id] ?? ""
            if !val.isEmpty || !field.label.isEmpty {
                items.append(FieldItem(id: field.id, label: field.label, value: val, kind: .secret))
            }
        }

        // URL
        if let url = credential.urlString, !url.isEmpty {
            items.append(FieldItem(id: Self.urlRowID, label: "웹사이트", value: url, kind: .link))
        }

        // 메모
        if let memo = credential.memo, !memo.isEmpty {
            items.append(FieldItem(id: Self.memoRowID, label: "메모", value: memo, kind: .plain))
        }

        return items
    }
}
