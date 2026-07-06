# 15 화면 보호 + 스크린샷 대응 (F-11 잔여)

- 이슈: #15  ·  PRD: F-10, F-11 (7.7)  ·  마일스톤: M5
- 상태: in-progress

## 목표
화면 녹화·미러링 중에는 앱 화면을 가려 민감 정보가 캡처물에 남지 않게 하고, 스크린샷이 찍히면 사후에 사용자에게 경고한다. iOS는 스크린샷 원천 차단 API가 없으므로 "가능한 범위" 대응임을 코드·문서에 명시한다.

## 배경 — 이미 된 것 / 남은 것
- **F-10 (백그라운드 화면 보호) = 완료.** PR #26(`59002eb`)에서 `RootView`가 `.inactive` 시 `PrivacyShieldView` 오버레이, `.background` 시 `AppLockController.lock()` 재잠금을 이미 처리한다. 이 이슈에서 **재구현하지 않는다.**
- **F-11 (스크린샷·녹화 대응) = 이번 작업.** 이슈 작업 범위 중 아래 2개가 미구현이다.
  - `UIScreen.isCaptured` 관찰 → 캡처 중 화면 가림
  - `userDidTakeScreenshotNotification` 사후 감지 → 경고
- 보안 입력 레이어 트릭(PRD 7.7 3번, `UITextField` secure-entry)은 **선택 항목이라 이번 스코프에서 제외**한다(비공식 기법·OS 업데이트 취약). exec-plan에 제외 사유를 남긴다.

## 범위 결정
- **가림 대상 = 앱 전역.** 캡처(`isCaptured`) 중에는 RootView 레벨에서 전체를 가린다. 로컬 전용 앱이라 캡처 중 목록/상세 어디든 노출이 곧 유출이므로, 화면별로 나누지 않고 전역 가림이 단순하고 누락이 없다.
- **스크린샷 경고 = 전역 토스트.** 찍힌 뒤라 차단은 불가하므로, 기존 `MAToast` 패턴으로 "스크린샷이 감지되었습니다" 수준 경고만 띄운다.

## 작업 분해
### Logic (myarchive-logic)
- [x] `ScreenCaptureMonitor`(@Observable, `Services/`) 신설 — `myArchive/Services/ScreenCaptureMonitor.swift`
  - `isCaptured: Bool` — `UIScreen.main.isCaptured` 초기값 + `UIScreen.capturedDidChangeNotification` 관찰로 갱신
  - `screenshotCount: Int` — `UIApplication.userDidTakeScreenshotNotification`마다 +1(UI가 `.onChange`로 토스트)
  - 블록 기반 `addObserver(queue:.main, [weak self])`, 토큰 배열 보관 후 `deinit`에서 전량 해제 → 누수·중복 없음
- [x] `MyArchiveApp`에서 `ScreenCaptureMonitor`를 `.environment(...)`로 주입
- [x] iOS 한계(원천 차단 불가) 근거 주석을 모니터 상단에 명시 + 보안 입력 레이어 트릭 제외 사유

### UI (myarchive-ui)
- [x] 캡처 가림 — `PrivacyShieldView` **재사용**(변형 신설 안 함). 브랜드 가림막이 전체를 덮어 유출 방지 목표 충족
- [x] `RootView`에서 `captureMonitor.isCaptured` 구독 → 오버레이 조건을 `isPrivacyShieldVisible || captureMonitor.isCaptured`로 OR 확장(F-10 privacy shield와 공존)
- [x] 스크린샷 감지 시 `.onChange(of: screenshotCount)` → `.maToast` 경고("스크린샷이 감지되었어요")
- [x] 디자인 토큰만 사용, 하드코딩 없음

### 검증 (myarchive-qa)
- [x] `swiftc -typecheck`(전체 34소스 EXIT=0) + SwiftLint(0) + SwiftFormat --lint(0) 통과
- [x] 경계면 점검: 주입 타입 일치, F-10 회귀 없음(scenePhase 스위치 보존), 옵저버 누수/중복 없음, 시크릿 평문 미노출
- [ ] **실기기 확인 핸드오프**(시뮬레이터 금지): 제어센터 화면 녹화 시작 시 가림·종료 복귀 / AirPlay 미러링 가림 / 스크린샷 시 토스트 / F-10 재잠금·앱스위처 회귀

## 후속 개선 후보 (이번 스코프 밖)
- `MAToast`는 초록 성공 배지 스타일이라 **경고 맥락엔 시각적으로 부적합**. 후속으로 warning variant(주황/경고 아이콘, `MAColor.accent`/`destructive` 계열) 검토 가능.
- 짧은 시간 연속 스크린샷 시 dismiss 타이머가 첫 등장 기준으로만 도는 경미한 UX 엣지.

## 의존성
1. Logic `ScreenCaptureMonitor` 시그니처 확정(`isCaptured`, 스크린샷 트리거) → 2. App 주입 → 3. UI(RootView 오버레이 + 토스트 배선) → 4. QA 교차 검증 → 실기기 핸드오프.

## 완료 조건
- 화면 녹화/미러링 중 앱 화면이 가려지고, 중지하면 원래 화면으로 복귀한다(실기기).
- 스크린샷을 찍으면 경고 토스트가 뜬다(실기기).
- iOS 한계(스크린샷 사전 차단 불가·보안 레이어 트릭 미적용)가 코드 주석/이 계획에 문서화되어 있다.
- F-10 재잠금·앱 스위처 가림은 기존 동작을 회귀시키지 않는다.

## 진행 로그
(exec-plan-sync가 커밋마다 채운다)
