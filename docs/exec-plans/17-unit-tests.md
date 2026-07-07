# 17 단위 테스트 보강

- 이슈: #17  ·  PRD: 전반(보안 7.x / 정렬 9.4 / 시간 3.4 / 정합성 13)  ·  마일스톤: M6
- 상태: done

## 목표
핵심 로직의 단위 테스트를 보안·정합성 우선으로 보강한다. 완료 시 `KeychainService` 저장/조회/삭제/키규칙, `CredentialSorter` 안정정렬·빈입력, `RelativeTime` 경계, 삭제 정합성, 마스킹 상태 전이가 XCTest로 검증된다.

## 현황 (이미 있는 것 — 중복 작성 금지)
- `CredentialSorterTests` — 즐겨찾기/전체 섹션·활동순, 이름순, 검색 단일섹션.
- `RelativeTimeTests` — 방금전/분/시간/일/주 경계, subtitle 수정/생성 접미사.
- `CredentialStoreTests` — cascade 메타 삭제 + Keychain 시크릿 정리(XCTSkip host 가드 포함).
- `DetailViewModelTests` — copy 토스트 문구, ClipboardExpiry 매핑/라벨.
- `PersistenceTests` — createdAt/updatedAt 터치, color hex 폴백, 방식 B 참조 저장, 커스텀필드 정렬.

## 작업 분해

### Logic (myarchive-logic) — 테스트 작성
- [x] **`KeychainServiceTests.swift` 신규** (최우선, 전용 파일 없음)
  - `set` → `get` 라운드트립: 동일 값 반환.
  - 같은 키 재저장 → 갱신(중복 아님, 마지막 값 반환).
  - `delete` 후 `get` → `nil`.
  - 없는 키 `delete` → `true`(errSecItemNotFound도 성공 취급).
  - 키 규칙: `passwordRef(for:) == "pw_\(uuid)"`, `valueRef(for:) == "cf_\(uuid)"`.
  - Keychain 접근 불가 host면 `XCTSkip`(CredentialStoreTests 패턴 재사용), `tearDown`에서 잔여 키 정리.
- [x] **`CredentialSorterTests` 보강**
  - 동일 활동시각 tie-break: `serviceName` 오름차순 안정정렬. → **구현이 tie-break 미지원**(아래 "구현-명세 불일치" 참조). 테스트는 과단정 없이 집합 검증 + 주석 기록.
  - 빈 입력: `[]` → favoriteRecent는 "전체" 0건, name/검색도 0건 섹션 처리.
- [x] **`DetailViewModelTests` 보강 (마스킹 상태)**
  - `reveal(id:)` → `revealedFields`에 포함(해제).
  - `resetReveal()` → `revealedFields` 비움(화면 이탈 재마스킹). `@MainActor`라 async 테스트.
  - 단방향 확인: 이미 해제된 필드에 `reveal` 재호출해도 여전히 해제 상태(토글 아님).
  - 조회 실패 경로: `passwordLoadFailed` 유발 시 해당 행 `kind == .error`이고 `copy(.error)`는 클립보드에 쓰지 않음(값 계약).

### 검증 (myarchive-qa)
- [x] `swiftc -typecheck`로 테스트 파일 컴파일 정합성 확인(시뮬레이터 금지). → error 0 / warning 0.
- [x] SwiftLint / SwiftFormat lint 통과. → 위반 0.
- [x] `project.yml`이 `myArchiveTests/`를 glob으로 잡는지 확인 — 신규 파일 자동 포함 여부(아니면 `xcodegen generate` 필요 안내). → xcodegen generate로 타깃 자동 포함 확인.
- [ ] **실기기 실행은 사용자 핸드오프**: Keychain·`@MainActor` 타이머 케이스는 실기기 `xcodebuild test`에서 사람이 확인(TESTING.md 실행 절차).

## 의존성
Logic가 테스트 4파일 작성 → QA가 typecheck/lint + 구조 확인 → 사용자 실기기 실행. 파일 간 의존 없음(병렬 작성 가능).

## 범위 밖 (명시)
- **22초 자동 재마스킹 타이머**: `reveal` 내부 `Task.sleep(22s)` 하드코딩 — 결정적 테스트하려면 클록/지연 주입 리팩터 필요. 이번 범위 밖(리팩터는 별도 이슈). 단방향·이탈 재마스킹만 검증.
- 구조적 테스트(`__tests__/structural/`), UI 테스트(XCUITest) — 이슈 체크박스상 미선택.

## 구현-명세 불일치 (발견 — (c) 기록만, 이번 범위 밖)
`CredentialSorter.byActivity`는 `activityDate` 내림차순만 비교하고 **동일 시각의 `serviceName` 오름차순 tie-break을 하지 않는다**(CredentialSorter.swift:31). 반면 `docs/TESTING.md`는 "동일 시각이면 serviceName 오름차순(안정 정렬)"을 명세한다 → 구현과 문서가 어긋난다.
- Swift 5+ `sorted`가 stable이라 동일 시각의 상대 순서는 입력 순서를 보존할 뿐, 명세가 요구하는 serviceName 정렬은 아니다.
- 사용자 판단 (c): 지금은 구현·명세 모두 손대지 않고 이 불일치를 여기와 테스트 주석에 **기록만** 한다. 향후 tie-break 구현 추가 또는 TESTING.md 완화는 별도 이슈.

## 완료 조건
- `KeychainServiceTests` 신규 존재, 저장/조회/삭제/키규칙 케이스 커버.
- `CredentialSorter` 안정정렬·빈입력, 마스킹 단방향·이탈 재마스킹, 조회실패 `.error` 경로 커버.
- 전체 테스트 파일 typecheck + lint 통과.
- 시크릿 평문을 테스트에 하드코딩하되 실 사용자 값 아님(더미), `tearDown`에서 Keychain 잔여 없음.
- TESTING.md 우선순위(보안·정합성 > 정렬/시간 > 마스킹) 순으로 채움.

## 진행 로그
- 2026-07-07: 테스트 3파일 작성(KeychainServiceTests 신규 + CredentialSorterTests·DetailViewModelTests 보강). QA 전체 PASS(typecheck error0/warning0, lint 위반0, 경계면 교차검증 일치). tie-break 불일치는 (c) 기록만. — 변경 파일: myArchiveTests/KeychainServiceTests.swift, myArchiveTests/CredentialSorterTests.swift, myArchiveTests/DetailViewModelTests.swift
