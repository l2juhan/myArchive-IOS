import Foundation
import SwiftData

/// 추가/수정 폼의 드래프트 상태·저장 로직 — 방식 B(PRD 9 / Design.md 3.7).
/// 시크릿(비밀번호·커스텀 값)은 표시·저장 시점에만 Keychain으로 오가고,
/// SwiftData 메타에는 참조 키만 남긴다. 평문은 이 드래프트(인메모리)에만 머문다.
@Observable
final class AddEditViewModel {
    /// 인메모리 커스텀 필드 초안 — SwiftData `CustomField`와 분리(평문 value 보관).
    /// id는 저장 시 Keychain valueRef 키의 기반이자 편집 매칭 키가 된다.
    struct DraftField: Identifiable {
        let id: UUID
        var label: String
        var value: String

        init(id: UUID = UUID(), label: String = "", value: String = "") {
            self.id = id
            self.label = label
            self.value = value
        }
    }

    // MARK: 드래프트(양방향 바인딩 대상)

    var serviceName = ""
    var username = ""
    var password = ""
    var colorHex = "" // 빈 값이면 저장 시 서비스명 해시로 폴백(F-15)
    var urlString = ""
    var memo = ""
    var isFavorite = false
    var fields: [DraftField] = []

    /// 편집 대상(신규면 nil). 저장 시 재사용.
    @ObservationIgnored private let editing: Credential?

    /// serviceName이 트림 후 비면 저장 불가.
    var isValid: Bool {
        !serviceName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 신규면 editing: nil. 편집이면 메타 + Keychain 시크릿(비밀번호·각 커스텀 값)을 드래프트로 로드.
    init(editing: Credential? = nil) {
        self.editing = editing
        guard let editing else { return }
        serviceName = editing.serviceName
        username = editing.username
        colorHex = editing.colorHex
        urlString = editing.urlString ?? ""
        memo = editing.memo ?? ""
        isFavorite = editing.isFavorite
        password = KeychainService.get(editing.passwordRef) ?? ""
        fields = editing.customFields
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { DraftField(id: $0.id, label: $0.label, value: KeychainService.get($0.valueRef) ?? "") }
    }

    // MARK: 커스텀 필드 초안 조작(인라인)

    /// 빈 초안 하나 추가.
    func addField() {
        fields.append(DraftField())
    }

    /// 초안 배열에서 제거(인라인 삭제).
    func removeField(_ field: DraftField) {
        fields.removeAll { $0.id == field.id }
    }

    // MARK: 저장 — 방식 B

    /// 메타는 SwiftData, 시크릿은 Keychain에 나눠 저장한다.
    /// 반환값: 시크릿 Keychain 저장이 모두 성공하면 true(실패 시 UI가 안내).
    @discardableResult
    func save(context: ModelContext) -> Bool {
        let credential = editing ?? Credential(serviceName: "", username: "", passwordRef: "")

        // 메타
        credential.serviceName = serviceName
        credential.username = username
        credential.colorHex = resolvedColorHex
        credential.urlString = normalized(urlString)
        credential.memo = normalized(memo)
        credential.isFavorite = isFavorite

        // 비밀번호(참조 키는 최초 1회 생성)
        if credential.passwordRef.isEmpty {
            credential.passwordRef = KeychainService.passwordRef(for: credential.id)
        }
        var secretsOK = store(password, for: credential.passwordRef)

        if editing == nil {
            context.insert(credential)
        } else {
            credential.updatedAt = .now // 수정 이력 갱신(PRD 9.4)
        }

        secretsOK = syncCustomFields(on: credential, context: context) && secretsOK

        try? context.save()
        return secretsOK
    }

    // MARK: 저장 헬퍼

    /// 색상 폴백 — 미선택(빈 값)이면 서비스명 해시 색(F-15 / Design.md 1.2).
    private var resolvedColorHex: String {
        let picked = colorHex.trimmingCharacters(in: .whitespaces)
        return picked.isEmpty ? MAAvatarPalette.fallbackHex(for: serviceName) : picked
    }

    /// 빈 문자열은 nil로(옵셔널 메타 정규화).
    private func normalized(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// 커스텀 필드 초안을 SwiftData·Keychain에 동기화(Design.md 3.7).
    /// - 라벨·값 모두 빈 초안은 폐기(저장 안 함).
    /// - 초안에서 사라진 기존 필드는 SwiftData·Keychain(valueRef)에서 함께 제거.
    /// - 남은 초안은 순서대로 label/sortOrder는 메타에, value는 valueRef에 저장.
    private func syncCustomFields(on credential: Credential, context: ModelContext) -> Bool {
        // 라벨·값 둘 다 빈 초안 폐기
        let keptDrafts = fields.filter { draft in
            !draft.label.trimmingCharacters(in: .whitespaces).isEmpty ||
                !draft.value.trimmingCharacters(in: .whitespaces).isEmpty
        }
        let keptIDs = Set(keptDrafts.map(\.id))

        // 초안에서 사라진 기존 필드 정리(메타 + 시크릿). 순회 중 삭제 대비 복사본 사용.
        for existing in Array(credential.customFields) where !keptIDs.contains(existing.id) {
            KeychainService.delete(existing.valueRef)
            context.delete(existing)
        }

        var existingByID = Dictionary(
            uniqueKeysWithValues: credential.customFields.map { ($0.id, $0) }
        )

        var ok = true
        for (index, draft) in keptDrafts.enumerated() {
            let field: CustomField
            if let matched = existingByID[draft.id] {
                matched.label = draft.label
                matched.sortOrder = index
                field = matched
            } else {
                field = CustomField(
                    id: draft.id,
                    label: draft.label,
                    valueRef: KeychainService.valueRef(for: draft.id),
                    sortOrder: index,
                    credential: credential
                )
                context.insert(field)
                existingByID[draft.id] = field
            }
            if !store(draft.value, for: field.valueRef) { ok = false }
        }
        return ok
    }

    /// Keychain 저장 시도 — 실패는 삼키지 않고 성공 여부로 돌려준다(PRD 13 안내 연계).
    private func store(_ secret: String, for key: String) -> Bool {
        do {
            try KeychainService.set(secret, for: key)
            return true
        } catch {
            return false
        }
    }
}
