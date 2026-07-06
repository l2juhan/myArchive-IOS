# 11 선택적 앱 잠금 + 설정 영속화

- 이슈: #11  ·  PRD: F-5, F-7, F-8, F-10, F-14  ·  마일스톤: M4
- 상태: planning

## 목표
앱 잠금 ON일 때 두 가지를 추가로 완성한다.
1. **백그라운드 재잠금** — 홈으로 나갔다 복귀하면 `LockView`가 다시 뜨고 재인증을 요구(PRD 7.4).
2. **앱 스위처 프라이버시 오버레이 (F-10)** — 앱 전환 순간 앱 스위처 스냅샷에 민감 정보가 노출되지 않도록 반투명 블러 가림막을 씌운다(PRD F-10).

이슈 #11의 나머지 항목(진입 게이트·설정 영속·지금 잠그기·AuthService)은 선행 PR #4/#10에서 이미 완료.

## 현황 (재사용 자산 — 이미 완료)
- ✅ `AuthService.authenticate()` — 생체→기기 암호 폴백.
- ✅ `AppLockController.lock()` — 잠금 상태 재설정.
- ✅ `RootView` 잠금 게이트 — `isAppLockEnabled && !isUnlocked` → `LockView(.task 자동 인증)`.
- ✅ 설정 '지금 잠그기' + `@AppStorage` 3종 영속.
- ✅ `sortMode` 소비(`CredentialListView`), `ClipboardService.copy` 준비.

## 남은 구현

### A. ScenePhase 재잠금 + 프라이버시 오버레이 (MyArchiveApp 또는 RootView)

iOS에서 앱 스위처 스냅샷은 **`.inactive` 전이 시점**에 이미 찍힌다. 따라서 가림막은 `.inactive`에서 올리고, 재잠금은 `.background`에서 한다.

```
.active      → 가림막 숨김
.inactive    → isAppLockEnabled이면 가림막 표시 (스냅샷 전 가림)
.background  → isAppLockEnabled이면 lockController.lock() (재진입 게이트)
```

- **가림막** — 앱 콘텐츠 위에 전체 덮는 `ZStack` 오버레이. 반투명 frosted glass(`ultraThinMaterial`) + 앱 아이콘/브랜드 중앙 배치(Lock 화면 BrandIconView 재사용 또는 단순 아이콘). 애니메이션 없이 즉시 등장(스냅샷 타이밍에 맞춰야 함).
- **재잠금 루프 방지** — `.inactive`에서는 `lock()`을 호출하지 않음. Face ID 시스템 시트가 `.inactive`를 유발하므로, `.inactive`에서 잠그면 인증 도중 재잠금 루프 발생.

## 작업 분해

### Logic (myarchive-logic)
- [ ] `AppLockController`에 `isPrivacyShieldVisible: Bool` 상태 추가(또는 ScenePhase를 RootView에서 직접 처리 — 단순하면 후자 선호).

### UI (myarchive-ui)
- [ ] **ScenePhase 관찰 배선** — `MyArchiveApp` body 또는 `RootView`에 `@Environment(\.scenePhase)` + `.onChange(of: scenePhase)`:
  - `.active` → 가림막 숨김.
  - `.inactive` && `isAppLockEnabled` → 가림막 표시.
  - `.background` && `isAppLockEnabled` → `lockController.lock()` (가림막은 이미 표시됨).
- [ ] **PrivacyShieldView** — 전체화면 오버레이. `ZStack { Color.clear.background(.ultraThinMaterial) }` + 중앙에 `BrandIconView`(84×84, 기존 LockView private struct에서 접근 가능하도록 분리 또는 복사). `.ignoresSafeArea()`.
- [ ] **ZStack 오버레이 배선** — `RootView`의 최상위 `Group` 위에 조건부 오버레이(`if isPrivacyShieldVisible { PrivacyShieldView() }`).

### 검증 (myarchive-qa)
- [ ] `swiftc -typecheck` 통과.
- [ ] SwiftLint 0 violations.
- [ ] 경계 확인 — 재잠금 `lockController.lock()` 단일 경로, `isAppLockEnabled` 가드.
- [ ] **실기기 확인 핸드오프** (시뮬레이터 금지):
  - 잠금 ON → 인증 해제 → 홈 스와이프(앱 스위처 확인) → 스냅샷이 블러/아이콘으로 가려짐.
  - 잠금 ON → 앱 복귀 → 잠금 화면 등장 + Face ID 재요구.
  - 잠금 OFF → 백그라운드/복귀에 아무 변화 없음(재잠금·가림막 없음).
  - Face ID 시트 활성 중 `.inactive` 발생해도 재잠금 루프 없음.

## 의존성
1. Logic: `AppLockController`에 `isPrivacyShieldVisible` 추가 (선행, 또는 RootView 로컬 `@State`로 처리).
2. → UI: ScenePhase 배선 + `PrivacyShieldView`.
3. → QA: 타입체크/lint + 실기기 핸드오프.

## 완료 조건
- 앱 잠금 ON: 앱 전환 시 스위처 스냅샷이 프라이버시 오버레이로 가려진다.
- 앱 잠금 ON: 백그라운드 후 재진입 시 재인증 요구.
- 앱 잠금 OFF(기본): 재진입·앱 전환에 아무 변화 없음.
- `.inactive`에서 재잠금하지 않아 인증 루프 없음.
- 저장 보호(Keychain) 항상 적용(기존 그대로).
- 설정 값(잠금/만료/정렬) 앱 재실행 후 유지(회귀 없음).
- 타입체크·lint 통과.

## 범위 밖 (별도 이슈)
- **F-11 스크린샷/화면 녹화 대응** — `UIScreen.isCaptured` 관찰 + `userDidTakeScreenshotNotification`. M5 별도 이슈.
- **F-4 필드별 복사 배선** — `CopyButton` → `ClipboardService.copy` 연결 + 초록 체크. M5 별도 이슈.

## 진행 로그
(exec-plan-sync가 커밋마다 채운다)
