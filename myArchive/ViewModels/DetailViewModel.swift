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
        case error // Keychain 로드 실패 — 값 없음, 복사/마스킹 해제 불가
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

    /// 현재 마스킹이 해제된 시크릿 필드 id 집합. 22초 후 또는 화면 이탈 시 비운다(PRD 6.2).
    private(set) var revealedFields: Set<UUID> = []

    // MARK: - 초기화 (표시 시점 시크릿 조회, PRD 6.1)

    init(credential: Credential) {
        self.credential = credential
        isFavorite = credential.isFavorite
        // 비밀번호 조회 — nil은 Keychain 로드 실패로 보존(빈 값과 구분)
        if let pw = KeychainService.get(credential.passwordRef) {
            passwordLoaded = pw
        } else {
            passwordLoadFailed = true
        }
        // 커스텀 필드 값 조회
        var vals: [UUID: String] = [:]
        var failed: Set<UUID> = []
        for field in credential.customFields {
            if let val = KeychainService.get(field.valueRef) {
                vals[field.id] = val
            } else {
                failed.insert(field.id)
            }
        }
        customValues = vals
        customLoadFailed = failed
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

    /// 필드 값 복사 — ClipboardService로 위임. 평문은 이 호출 이후 어디에도 보관하지 않는다.
    /// .error 항목은 값이 없으므로 복사하지 않는다.
    func copy(item: FieldItem, expirySec: Int) {
        guard item.kind != .error else { return }
        ClipboardService.copy(item.value, expiresInSeconds: expirySec)
    }

    /// 복사 토스트 subtitle 문구 — 순수 함수. "N초 후 자동 삭제".
    static func copyToastSubtitle(seconds: Int) -> String {
        "\(seconds)초 후 자동 삭제"
    }

    /// 시크릿 필드 마스킹 해제 후 22초 자동 재마스킹 타이머를 (재)시작한다(PRD 6.2).
    @MainActor
    func reveal(id: UUID) {
        revealedFields.insert(id)
        revealTimerTask?.cancel()
        revealTimerTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 22_000_000_000)
            } catch {
                return // 취소(다른 필드 reveal·화면 이탈) 시 조용히 종료
            }
            self?.resetReveal()
        }
    }

    /// 모든 마스킹을 되돌리고 타이머를 정리한다. 화면 이탈(onDisappear)에서도 호출.
    @MainActor
    func resetReveal() {
        revealedFields.removeAll()
        revealTimerTask?.cancel()
        revealTimerTask = nil
    }

    // MARK: - Private

    @ObservationIgnored private var passwordLoaded: String?
    @ObservationIgnored private var passwordLoadFailed = false
    @ObservationIgnored private var customValues: [UUID: String] = [:]
    @ObservationIgnored private var customLoadFailed: Set<UUID> = []
    @ObservationIgnored private var revealTimerTask: Task<Void, Never>?

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
        if passwordLoadFailed {
            items.append(FieldItem(id: Self.passwordRowID, label: "비밀번호", value: "", kind: .error))
        } else if let pw = passwordLoaded, !pw.isEmpty {
            items.append(FieldItem(id: Self.passwordRowID, label: "비밀번호", value: pw, kind: .secret))
        }

        // 커스텀 필드 (sortOrder 순)
        for field in credential.customFields.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            if customLoadFailed.contains(field.id) {
                items.append(FieldItem(id: field.id, label: field.label, value: "", kind: .error))
            } else {
                let val = customValues[field.id] ?? ""
                if !val.isEmpty || !field.label.isEmpty {
                    items.append(FieldItem(id: field.id, label: field.label, value: val, kind: .secret))
                }
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
