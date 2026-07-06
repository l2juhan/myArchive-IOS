# 12 시크릿 마스킹/터치 해제

- 이슈: #12  ·  PRD: F-3  ·  마일스톤: M5
- 상태: done

## 목표
상세 화면의 시크릿 필드(아이디·비밀번호·커스텀)가 기본 blur(5px)+눈 힌트로 가려지고,
탭하면 해당 필드만 평문으로 드러난다(단방향). 약 22초 경과 또는 화면 이탈 시 전체 재마스킹된다.

## 현재 상태
- `CredentialDetailView.DetailFieldRow` — blur(5)+눈 아이콘 이미 표시 중 (정적)
- `DetailViewModel` — `revealedFields` 없음, reveal 메서드 없음, 타이머 없음
- `MAMotion.reveal` (`easeInOut 0.20s`) 이미 정의됨

## 작업 분해

### Logic (myarchive-logic)
- [ ] `DetailViewModel`에 `private(set) var revealedFields: Set<UUID> = []` 추가
- [ ] `reveal(id: UUID)` 메서드: Set에 id 추가 → 22초 타이머 (재시작)
- [ ] `resetReveal()` 메서드: Set 비우기, 진행 중 타이머 취소
- [ ] 타이머는 `Task`+`try await Task.sleep` 방식으로 구현, 새 reveal 시 기존 Task 취소 후 새로 시작 (마지막 탭 기준 22초)

### UI (myarchive-ui)
- [ ] `DetailFieldRow`에 `isRevealed: Bool` 파라미터 추가
- [ ] `.secret` 케이스: `isRevealed`가 false면 `blur(radius:5)`+눈 아이콘, true면 blur 제거+아이콘 숨김, `withAnimation(MAMotion.reveal)` 전환
- [ ] blur 영역(행 전체) 탭 시 `vm.reveal(id:)` 호출 — `isRevealed`가 false일 때만 적용 (단방향)
- [ ] `CredentialDetailView`에서 `DetailFieldRow` 호출 시 `isRevealed: vm.revealedFields.contains(item.id)` 전달
- [ ] `.onDisappear { vm.resetReveal() }` 추가

### 검증 (myarchive-qa)
- [ ] `swiftc -typecheck` + `swiftlint` 통과
- [ ] **실기기 확인 항목**: 탭 전 blur 표시, 탭 후 해당 필드만 평문, 22초 후 자동 재마스킹, 다른 화면 이탈 후 재진입 시 전체 재마스킹, URL·메모는 항상 평문

## 의존성
Logic (revealedFields + reveal/resetReveal API) → UI (DetailFieldRow, onDisappear) → QA

## 완료 조건
- 시크릿 필드: 진입 시 전부 blur, 탭 후 해당 1개만 평문, 나머지 blur 유지
- 단방향: 평문 상태에서 재탭해도 다시 가려지지 않음
- 22초 타이머: 마지막 reveal 탭 기준으로 재시작, 만료 시 전체 재마스킹
- 화면 이탈(pop/dismiss/sheet 닫기): 재진입 시 전체 재마스킹
- URL·메모: blur 없음

## 진행 로그
- Logic: DetailViewModel — revealedFields/reveal/resetReveal/타이머 구현 완료
- UI: CredentialDetailView/DetailFieldRow — 블러 전환·탭 제스처·onDisappear 구현 완료
- QA: swiftc typecheck PASS · swiftlint PASS · 경계면 교차 검증 전항목 PASS
