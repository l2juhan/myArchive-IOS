# 34 시크릿 값 텍스트를 iOS 시스템 폰트로 통일 (모노스페이스 제거)

- 이슈: #34  ·  PRD: 해당 없음(Design.md 1.3 타이포그래피 위계)  ·  마일스톤: —
- 상태: done

## 목표
저장된 아이디·비밀번호·커스텀 값의 표시/입력 텍스트가 나머지 화면과 **같은 iOS 시스템 폰트(SF Pro / Apple SD Gothic Neo)**로 렌더된다. 현재 이 값들만 모노스페이스(고정폭)라 글씨체가 달라 보이는데, 이를 일반 시스템 폰트로 통일한다.

## 진짜 범위 (사용자 확인 반영)
- 이슈 제목은 "전체 감사"처럼 읽히지만, 실제 불편함은 **시크릿 값 텍스트만 글씨체가 다른 것**(모노스페이스)이다.
- 원인: `MAType.secretValue = Font.system(..., design: .monospaced)` — 이 토큰이 4곳에서 시크릿 값에 쓰인다.
  | 위치 | 맥락 |
  | --- | --- |
  | CredentialDetailView.swift:200 | 상세 화면 시크릿 값 표시 |
  | CustomFieldRow.swift:22 | 커스텀 필드 값 입력 |
  | AddEditView.swift:115 | 추가/수정 시크릿 입력 |
  | AddEditView.swift:226 | `mono ? secretValue : fieldValue` 분기 |
- 나머지 하드코딩 `.font(.system(...))`(아이콘 심볼 사이징 ~18곳, 아바타 동적 크기)는 **이번 이슈 대상 아님** — 글씨체 불만과 무관.

## 디자인 스펙 변경 (중요)
- Design.md 1.3(59행)·필드값 표(71행)에 **"시크릿 값·비밀번호 입력은 모노스페이스"** 가 확정값으로 박혀 있다. 이를 뒤집는 변경이므로 **Design.md 1.3과 DESIGN_SYSTEM.md를 함께 갱신**해야 한다(단일 소스 동기화).
- 참고 트레이드오프: 모노스페이스는 비밀번호의 유사 문자(0/O, 1/l/I) 구분에 유리했다. 시스템 폰트로 바꾸면 나머지와 톤은 통일되나 그 구분 이점은 줄어든다. → 사용자 미감 우선으로 통일 진행.

## 작업 분해
### Logic (myarchive-logic)
- [x] `MAType.secretValue`에서 `design: .monospaced` 제거 → `fieldValue`와 동일한 시스템 폰트(16 medium)가 되게 한다.
  - 결과적으로 secretValue == fieldValue. **토큰을 유지(주석만 "모노 제거, 시스템 폰트" 갱신)**해 4곳의 호출부 변경을 최소화한다.
  - AddEditView:226의 `mono` 분기는 그대로 유지(두 갈래 폰트가 같아져도 향후 재분기 여지를 위해 남김, 동작 영향 없음).

### UI (myarchive-ui)
- [x] 시크릿 값 표시/입력이 시스템 폰트로 렌더되는지 확인(상세·추가/수정·커스텀 필드) — 실기기에서 확인 완료.
- [x] 마스킹(블러)·눈 아이콘·복사 동작은 그대로(폰트만 변경, 레이아웃/보안 동작 불변) 확인.

### 검증 (myarchive-qa)
- [x] `swiftc -typecheck` + SwiftLint + SwiftFormat --lint 통과.
- [x] `monospaced` 잔존 0건 grep 재확인.
- [x] 시크릿 값 폰트 == 일반 필드값 폰트 정합 확인. 실기기 시각 확인 완료(사용자).

## 문서 동기화 (docs-sync 대상)
- [x] `docs/references/Design.md` 1.3(59행 문장 + 71행 "시크릿=모노" 표기, 136행) → 시크릿 값도 시스템 폰트로 표시하도록 수정.
- [x] `docs/DESIGN_SYSTEM.md` MAType 매핑/사용 규칙(20행 "시크릿 값은 모노스페이스") → 갱신.
- doc-sync-map: design-tokens.

## 의존성
Logic(토큰 정의 변경) → UI(시각 확인) → QA(정합/잔존) → 문서 동기화.

## 완료 조건
- [x] 시크릿 값(아이디·비밀번호·커스텀) 표시·입력이 일반 필드값과 동일한 시스템 폰트로 렌더(모노스페이스 제거).
- [x] 마스킹·복사·클립보드 만료 등 보안 동작 불변.
- [x] typecheck/lint 통과, `monospaced` 잔존 0.
- [x] Design.md 1.3 · DESIGN_SYSTEM.md 동기화 완료.
- [x] (실기기) 상세·추가/수정 화면에서 시크릿 값 글씨체가 나머지와 통일됐는지 확인.

## 진행 로그
- `MAType.secretValue`에서 `design: .monospaced` 제거(16 medium, 시스템 폰트). 호출부 4곳(CredentialDetailView, CustomFieldRow, AddEditView×2)은 토큰 유지로 변경 없음. — 변경 파일: myArchive/DesignSystem/MAType.swift
- `Design.md` 1.3(59행 문장, 71행 표), 136행(추가/수정 커스텀 필드 값 설명) 갱신. `DESIGN_SYSTEM.md` 사용 규칙(20행) 갱신. — 변경 파일: docs/references/Design.md, docs/DESIGN_SYSTEM.md
- 검증: `monospaced` 잔존 0, SwiftLint/SwiftFormat --lint 통과, `swiftc -typecheck` 전체 통과.
- 실기기 시각 확인 완료(사용자 테스트 성공).
