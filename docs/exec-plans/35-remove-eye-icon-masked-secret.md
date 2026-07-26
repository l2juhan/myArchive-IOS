# 35 시크릿 마스킹(블러) 상태의 눈 아이콘 제거

- 이슈: #35  ·  PRD: 해당 없음 (Design.md — 시크릿 필드 마스킹/reveal)  ·  마일스톤: 없음
- 상태: done

## 목표
상세 화면 시크릿 필드가 블러(마스킹) 상태일 때 우측에 뜨는 눈(eye) 아이콘을 없앤다.
블러가 곧 마스킹 힌트이므로 아이콘 없이도 탭→reveal→재마스킹 동작은 그대로 유지된다.

## 작업 분해
### UI (myarchive-ui)
- [x] `CredentialDetailView.swift` `valueText`의 `.secret` 케이스에서 `.overlay(alignment: .trailing)` 눈 아이콘 블록(L204~210) 제거
- [x] `.blur(radius: isRevealed ? 0 : 5)` 및 `.animation(MAMotion.reveal, value: isRevealed)`는 유지
- [x] `#Preview`로 마스킹/reveal 두 상태 시각 확인 (기존 프리뷰가 마스킹 상태 기본 표시, reveal은 탭으로 확인 — 신규 프리뷰 추가 없이 구조 유지)

### Logic (myarchive-logic)
- 없음 (표시 로직만 변경, reveal/재마스킹 상태 로직은 손대지 않음)

### 검증 (myarchive-qa)
- [x] `swiftc -typecheck` + SwiftLint + SwiftFormat --lint 통과 (전체 34개 소스, 진단 0건)
- [x] 블러 상태에서 눈 아이콘이 사라지고, 탭 gesture(L190~192)로 reveal이 정상 동작하는지 경계 확인
- [x] 하드코딩 토큰 없이 DesignSystem 토큰만 남았는지 확인 (`.secret` 케이스는 `MAType.secretValue`/`MAColor.ink`/`MAMotion.reveal`만 사용 — `MAColor.secondary`·`Image`는 `.error` 케이스에서 계속 쓰여 제거 대상 아니었음, 계획상 추정과 달랐던 부분)

## 의존성
UI 단독 작업. Logic 변경 없음. QA는 UI 완료 후 타입체크/lint + reveal 동작 경계만 확인.

## 완료 조건
- 마스킹 상태에서 눈 아이콘이 보이지 않는다
- 블러(radius 5) 마스킹 표현은 유지된다
- 탭 → reveal → 일정 시간 후 재마스킹 기존 동작 유지
- 라이트 모드 전용, DesignSystem 토큰만 사용(하드코딩 없음)
- 타입체크/lint 통과

## 진행 로그
- 2026-07-26: 눈 아이콘 overlay 제거 + QA 타입체크/lint/경계 검증 PASS — 변경 파일: myArchive/Views/Detail/CredentialDetailView.swift
