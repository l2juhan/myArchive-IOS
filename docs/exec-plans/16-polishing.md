# 16 폴리싱(검색·빈/에러·모션·글꼴)

- 이슈: #16  ·  PRD: 해당 없음(PRD 12장 M6)  ·  마일스톤: M6
- 상태: done

## 목표
M6 마감 폴리싱. 콜드 스타트→목록이 매끄럽게 뜨고, **빈/검색0건/조회 실패** 세 가지 상태가 모두 명확하며, 모션이 전부 MAMotion 토큰을 경유해 일관되게 동작한다. 글꼴·검색은 현행이 이미 요건을 충족함을 확인·확정한다.

## 현황 요약(조사 결과)
- **검색**: 인메모리 필터(serviceName/username), 결과 0건 시 검색 포커스 유지 처리까지 이미 완료. → **변경 없음(현행 유지 결정)**.
- **빈/검색0건 상태**: `emptyState`·`noResultState` 구현 완료. → 시각 점검만.
- **조회 실패 상태**: **미구현**. `DetailViewModel`이 `KeychainService.get(...) ?? ""`로 실패(nil)를 빈 값으로 뭉개, 저장된 시크릿을 못 불러오면 필드 행이 **조용히 사라짐**. → 처리 대상.
- **모션**: MAMotion 토큰 존재·대부분 일관. **하드코딩 2곳** 잔재 — `SettingsView.swift:95`, `CopyButton.swift:27`(둘 다 `.easeInOut(duration: 0.2)`, `MAMotion.reveal`과 동일). → 토큰화.
- **글꼴**: 전부 시스템 폰트(SF Pro / Apple SD Gothic Neo) → 상업 배포 저작권 안전. → **시스템 폰트 유지 결정**. 이슈의 "저작권 안전 글꼴 찾기"는 "이미 안전 확인"으로 종결·문서화.

## 작업 분해

### Logic (myarchive-logic)
- [x] `DetailViewModel`: Keychain 조회 **실패(nil)** 와 **빈 값("")** 을 구분한다.
  - `FieldKind.error` 케이스 추가. `passwordLoaded: String?` + `passwordLoadFailed: Bool` + `customLoadFailed: Set<UUID>` 도입.
  - `get` nil → .error 행(생략하지 않음), 빈 값 → 기존 행 생략 유지.
  - `copy()`: `.error` 항목 guard로 복사 불가 처리.
- [x] 검색: 현행 유지 확정(인메모리, serviceName/username, 반응성 이상 없음).

### UI (myarchive-ui)
- [x] 모션 토큰 일관화: `SettingsView.swift:95`, `CopyButton.swift:27` → `MAMotion.reveal`.
- [x] 상세 **조회 실패 행** 렌더: `DetailFieldRow`에 `.error` case — exclamationmark.circle + "값을 불러올 수 없어요"(secondary). 복사 버튼 숨김.
- [x] 전반 시각 점검: 기존 구현이 Design.md와 정합 확인. 실행 확인은 실기기 핸드오프.

### 검증 (myarchive-qa)
- [x] `swiftc -typecheck` 에러 없음, `swiftlint` 경고 없음.
- [x] 경계면: FieldKind(.error/.secret/.link/.plain) ↔ UI 분기 정합, copy guard 정합.
- [x] 모션 잔재 grep: 하드코딩 duration 0건. 모든 animation이 MAMotion 경유 확인.
- 실기기 확인 핸드오프: ①콜드 스타트→목록 체감 ②빈/검색0건/조회 실패 3상태 시각 ③토스트·모달·리빌·펄스 모션 일관성.

## 의존성
1. Logic(실패 구분 API: `FieldItem` 실패 표현) →
2. UI(조회 실패 행 렌더). 모션 토큰 교체는 UI 독립(선후 무관).
3. QA는 위 완료 후 교차 검증 + 실기기 핸드오프 정리.

## 완료 조건
- 상세 화면에서 저장된 시크릿을 못 불러오는 상황이 **행 소멸이 아니라 명확한 안내**로 표시된다(빈 값과 구분).
- `withAnimation`/`.animation`이 전부 `MAMotion` 토큰 경유(하드코딩 duration 0건).
- 빈/검색0건/조회 실패 3상태가 모두 처리됨(실기기 시각 확인은 핸드오프 항목으로 남김).
- 글꼴은 시스템 폰트 유지로 확정, 저작권 안전 확인이 진행 로그/문서에 기록됨.
- typecheck/lint 통과, `/quality` 기준 충족.

## 진행 로그

- 검색·글꼴: 현행 유지 확정. 시스템 폰트(SF Pro/Apple SD Gothic Neo) → 상업 배포 저작권 안전.
- DetailViewModel: .error FieldKind 추가, passwordLoaded/passwordLoadFailed/customLoadFailed 도입. copy() guard.
- CredentialDetailView/DetailFieldRow: .error 케이스 렌더(아이콘+"값을 불러올 수 없어요"), 복사 버튼 숨김.
- SettingsView:95, CopyButton:27 → MAMotion.reveal 토큰화. 하드코딩 duration 잔재 0건.
- typecheck 에러 없음, swiftlint 경고 없음.
