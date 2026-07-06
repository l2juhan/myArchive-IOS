# 7 SwiftData 메타데이터 영속화

- 이슈: #7  ·  PRD: F-1  ·  마일스톤: M2
- 상태: in-progress

## 목표
더미가 아닌 SwiftData에서 계정을 읽고/쓰고/지우며, 삭제 시 메타(cascade)와 Keychain 시크릿이 함께 정리된다(PRD 13 정합성). color·createdAt·updatedAt·커스텀 필드 관계·방식 B(참조 키만) 동작을 단위 테스트로 보증한다.

## 현황 (선조사 결과 — 이미 구현됨)
직전 PR(#3 추가/수정, #4 설정)에서 영속화 골격은 대부분 완성됨:
- 모델 `Credential`/`CustomField`: `@Attribute(.unique)`, `@Relationship(deleteRule: .cascade, inverse:)`, sortOrder — 완료.
- `MyArchiveApp`: `ModelContainer(for: Credential.self, CustomField.self)` + `.modelContainer` — 완료.
- 목록 `CredentialListView`: `@Query` + 인메모리 검색 + `toggleFavorite`가 `modelContext.save()` — 완료.
- `AddEditViewModel.save`: 신규 `context.insert`/편집 시 `updatedAt=.now`, `passwordRef` 최초 1회 생성, `syncCustomFields`(cascade+sortOrder+Keychain 정리), colorHex 해시 폴백 — 완료.
- `KeychainService`: set/get/delete + passwordRef/valueRef 키 규칙 — 완료.
→ 이 항목들은 **점검·테스트만** 하고 재구현하지 않는다.

## 작업 분해

### Logic (myarchive-logic)
- [x] `Services/CredentialStore.swift` 신설 — 계정 삭제 정합성 프리미티브. `delete(_ credential:from context:)`:
  - `credential.customFields`의 모든 `valueRef`를 `KeychainService.delete`
  - `credential.passwordRef`를 `KeychainService.delete`
  - `context.delete(credential)`(CustomField 메타는 `.cascade`가 정리) → `try? context.save()`
  - 근거: SwiftData cascade는 메타만 지우고 Keychain 시크릿은 고아로 남음(PRD 13 위반) → 이 지점이 유일한 실질 격차.
  - 삭제 UI(상세 화면 삭제 모달)는 M3/M5 범위이므로 이번엔 **로직만** 제공(UI 미연결 OK, 다음 마일스톤이 호출).

### UI (myarchive-ui)
- [x] 변경 없음(확인만). 목록·추가/수정은 이미 SwiftData 연동. 상세 삭제 버튼은 M3/M5.

### 검증 (myarchive-qa)
- [x] `myArchiveTests/PersistenceTests.swift` 신설 — 인메모리 `ModelContainer(isStoredInMemoryOnly: true)`로:
  - 신규 저장: `createdAt`≈현재 시각, `updatedAt == nil`, `context`에 1건 fetch.
  - 편집 저장: `updatedAt != nil`(수정 이력 갱신), `createdAt` 불변.
  - colorHex 폴백: colorHex 빈 값으로 저장 → `MAAvatarPalette.fallbackHex(for:)`와 동일.
  - **방식 B 준수**: 저장된 `Credential`/`CustomField` 메타에 평문 비밀번호·커스텀 값이 **없고** `passwordRef`는 `pw_` 접두, `valueRef`는 `cf_` 접두만 보유.
  - 커스텀 필드: 3개 초안 저장 시 `sortOrder`가 0/1/2로 유지, 라벨·값 둘 다 빈 초안은 폐기.
- [x] `myArchiveTests/CredentialStoreTests.swift` 신설 — 삭제 정합성:
  - 커스텀 필드 있는 계정 삭제 → `context`에서 Credential·CustomField 0건(cascade 확인).
  - Keychain: 삭제 대상의 `passwordRef`/`valueRef` 조회가 `nil`(시크릿 정리 확인).
- [x] Keychain 부수효과 격리: 각 테스트는 고유 UUID 키를 쓰고 `tearDown`(또는 defer)에서 `KeychainService.delete`로 잔여 정리. (실기기 유닛 테스트가 실제 Keychain에 씀 — 잔여 남기지 않기.)
- [x] `swiftc -typecheck` + `swiftlint` + `swiftformat --lint` 통과. **시뮬레이터 빌드/test 금지** — 실기기 유닛 테스트는 사용자 핸드오프.

## 의존성
1. Logic: `CredentialStore` 신설 → 2. QA: 테스트가 `CredentialStore`·`AddEditViewModel`·`KeychainService`를 대상으로 작성. UI는 무변경 확인만.

## 완료 조건
- 앱 재실행 후 데이터 유지(영속 컨테이너 — 기존 동작, 실기기 확인).
- 시크릿 평문이 SwiftData에 저장되지 않음(참조 키만) — 테스트로 보증.
- 계정 삭제 시 메타(cascade) + Keychain 시크릿이 함께 제거 — `CredentialStore` + 테스트로 보증(PRD 13).
- 신규 createdAt=현재·updatedAt=nil, 편집 updatedAt=현재, colorHex 해시 폴백 — 테스트 통과.
- CustomField cascade·sortOrder 유지 — 테스트 통과.
- `swiftc -typecheck`/lint 통과, 실기기 유닛 테스트 통과(핸드오프).

## 진행 로그
- 구현: `myArchive/Services/CredentialStore.swift`(삭제 정합성 프리미티브) 신설. `@Relationship(.cascade)`가 남기는 Keychain 고아 시크릿(passwordRef+valueRef)을 메타 삭제와 함께 정리(PRD 13). 기존 영속화(모델·컨테이너·@Query·save·KeychainService)는 이미 완성이라 재구현 없이 점검만.
- 검증: `myArchiveTests/PersistenceTests.swift`(신규/편집 timestamp, colorHex 폴백, 방식 B 참조키, sortOrder/빈초안) + `myArchiveTests/CredentialStoreTests.swift`(cascade, Keychain 정리) 신설. 인메모리 컨테이너 + Keychain 부수효과 tearDown 격리.
- 기계 검증 통과: `swiftc -typecheck`(앱 모듈, exit 0) · `swiftlint`(0 violations) · `swiftformat --lint`(0 files). 테스트는 XCTest 링크 필요로 `-parse` + 시그니처 육안 대조.
- 실기기 핸드오프: `xcodebuild test`를 실기기 destination으로 실행(시뮬 금지), `testDeleteRemovesKeychainSecrets` skip 없이 통과 확인, 앱 재실행 후 데이터 유지 육안 확인.
