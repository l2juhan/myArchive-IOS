# 10 [Design] 잠금 화면 (LockView 시각 마감)

- 이슈: #10  ·  PRD: F-5  ·  마일스톤: M4
- 상태: done

## 목표
`LockView`를 Design.md 2.1 / `screenshots/01-lock-screen.png`대로 마감한다. 앱 잠금 ON일 때만 뜨는 진입 게이트로, 상단 캡션·앱 아이콘·브랜드·Face ID 펄스 트리거·주요/보조 버튼이 명세대로 배치되고 maPulse 링이 돈다.

## 현황 (재사용 자산)
- **Logic 완료** — `AuthService.authenticate()`(생체→기기암호 폴백), `AppLockController`(잠금 상태). 신규 로직 불필요.
- **통합 완료** — `RootView`가 `isAppLockEnabled` && `!isUnlocked`일 때 `LockView(isUnlocked:)`를 게이트로 노출.
- **LockView 골격만** — 그라데이션 배경·브랜드 텍스트·CTA·`authing` 상태·진입 자동 인증(`.task`)은 있음. **미구현: 상단 캡션 · 앱 아이콘 84 · Face ID 88 펄스 트리거 · 보조 버튼 · CTA 그림자.**

## 작업 분해

### Logic (myarchive-logic)
- 신규 없음. `authing` 바인딩은 이미 서브 텍스트("인증 중…")에 연결됨 — UI 재배치 시 그대로 유지.

### UI (myarchive-ui)
- [x] **색 토큰 추가** — `MAColor.faceIDButtonBG = #EAF1FC` 추가.
- [x] **앱 아이콘 84×84 (SwiftUI 코드 재현)** — `BrandIconView` private struct. `RoundedRectangle(cornerRadius:20, style:.continuous)` + `LinearGradient(#6768CE→#36368C)` + `key.horizontal.fill` 38pt 흰색.
- [x] **상단 캡션** — "잠겨 있어요" 13/semibold `captionAlt`.
- [x] **중앙 세로 스택** — BrandIconView → 브랜드 → 서브(`authing` 반영).
- [x] **Face ID 트리거** — 88×88 원형, `faceIDButtonBG`, `faceid` 글리프, `MAMotion.pulse` 스케일/투명도 링.
- [x] **주요 CTA** — 솔리드 인디고 + shadow(radius:8, y:4).
- [x] **보조 버튼** — "암호로 잠금 해제" 14/semibold `interactiveText`.
- [x] **레이아웃 정렬** — VStack(spacing:0) + Spacer 배분.
- [x] `#Preview` 갱신.

### 검증 (myarchive-qa)
- [x] `swiftc -typecheck` 통과 (오류 없음).
- [x] SwiftLint 0 violations.
- [x] 경계 확인 통과 — 인증은 `AuthService.authenticate()` 단일 경로, `authing` guard 중복 방지.
- [ ] **실기기 시각 확인 핸드오프** — 사용자가 `#Preview` 또는 실기기에서 확인 필요.

## 의존성
1. `MAColor.faceIDButtonBG` 토큰 추가 + `BrandIcon` 에셋 신설 (선행)
2. → `LockView` 재구성 (본작업)
3. → QA 타입체크/lint + 실기기 핸드오프

## 완료 조건
- Design.md 2.1의 6개 요소(캡션·아이콘·브랜드/서브·88 펄스 트리거·주요 CTA·보조 버튼)가 모두 렌더된다.
- maPulse 링이 `MAMotion.pulse`로 무한 반복 애니메이션.
- 라이트 모드 전용(v1), 그라데이션 `#FBFCFC→#E7EEEE`.
- Face ID 트리거·주요 CTA·보조 버튼 셋 다 인증을 트리거하고, 성공 시 `isUnlocked = true`.
- `#Preview`로 시각 확인 가능.
- 타입체크·lint 통과. DESIGN_SYSTEM.md 토큰 추가분 동기화(신규 `faceIDButtonBG`).

## 진행 로그
(exec-plan-sync가 커밋마다 채운다)
