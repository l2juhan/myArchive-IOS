# 04 설정 화면

- 이슈: #4  ·  PRD: F-7 (연관 F-5·F-8·F-14)  ·  마일스톤: M1
- 상태: done

## 목표
설정 화면을 Design.md 2.5의 커스텀 디자인(회색 캔버스 + 흰 카드 섹션 + 커스텀 세그먼트/토글 + 회색 헬퍼 텍스트)대로 마감한다. 네 섹션(보안·클립보드·목록 정렬·정보)이 실제 설정값(@AppStorage)과 양방향으로 연결되고, 보안 토글이 켜지면 "지금 잠그기" 행이 노출되어 실제로 앱을 다시 잠근다.

## 배경 / 현재 상태
- `myArchive/Views/Settings/SettingsView.swift`가 이미 **네이티브 `Form` 스캐폴드**로 존재한다. 값 배선(@AppStorage 3종)은 맞지만, 앱의 나머지 화면이 쓰는 커스텀 카드 디자인 언어와 불일치하고, 스크린샷(05-settings.png)의 커스텀 세그먼트/토글/헬퍼 텍스트와 다르다. → **재구성 대상.**
- `SettingsKey`(isAppLockEnabled·clipboardExpirySec·sortMode), `ClipboardExpiry`, `SortMode`는 `Models/AppSettings.swift`에 이미 있음 → 재사용.
- 커스텀 세그먼트 토큰(`MAColor.segmentTrack`, `MARadius.segment`, `MAMotion.segment`)은 정의만 돼 있고 사용처가 없음 → 이 작업에서 첫 사용(재사용 컴포넌트 신설).
- "지금 잠그기"는 `RootView`의 로컬 `@State isUnlocked`를 false로 되돌려야 하는데, 지금은 설정 화면에서 접근할 공유 상태가 없음 → 로직 배선 필요.
- `AuthService.biometryType`로 Face ID/Touch ID 구분 문구 가능(선택).

## 작업 분해

### Logic (myarchive-logic)
- [x] 공유 잠금 상태 도입: `AppLockController` 신설 (`myArchive/Services/AppLockController.swift`), `MyArchiveApp`에서 environment 주입, `RootView` 교체 완료.
- [x] "지금 잠그기" 액션: `lockController.lock()` + `dismiss()` 배선 완료.
- [x] 설정값 3종은 @AppStorage 직접 바인딩으로 처리.

### UI (myarchive-ui)
- [x] `SettingsView` 재구성: Form → ScrollView + MAColor.appBackground + 흰 카드 섹션.
- [x] `MASegmentedControl<T: Hashable>` 신설 (`myArchive/Views/Components/MASegmentedControl.swift`). matchedGeometryEffect 칩 애니메이션.
- [x] 보안 섹션: 토글 + isAppLockEnabled ON 시 "지금 잠그기" 행 노출 (withAnimation).
- [x] 클립보드·정렬 섹션: MASegmentedControl 적용.
- [x] 정보 섹션: 버전·저장방식·네트워크 3행.
- [x] 헬퍼 텍스트 4섹션 각 하단 배치.
- [x] #Preview 2종 (잠금 꺼짐 / 잠금 켜짐).

### 검증 (myarchive-qa)
- [x] `swiftc -typecheck` 통과 (exit 0).
- [x] `swiftlint` 경고 없음.
- [x] `swiftformat --lint` 0/25 files require formatting.
- [x] SettingsKey 키 일관성: Settings/CredentialListView/RootView 모두 동일 키 사용 확인.
- [x] AppLockController 배선: MyArchiveApp 주입 → RootView 게이트 → SettingsView 소비 정합.
- [ ] 실기기 시각·동작 확인 필요 (사용자 핸드오프).

## 의존성
1. Logic: `AppLockController` 시그니처(`isUnlocked`, `lock()`) + environment 키 확정 → 2. UI: 세그먼트 컴포넌트 → 보안 섹션(지금 잠그기)이 컨트롤러 소비 → 나머지 섹션 → 3. QA 교차 검증.

## 완료 조건
- 네 섹션이 명세대로 보이고, 세그먼트/토글 시각이 05-settings.png와 일치(라이트 모드 전용).
- 설정값 3종이 @AppStorage로 영속되고 목록 정렬/잠금 게이트에 즉시 반영.
- 보안 토글 ON 시 "지금 잠그기" 노출 + 탭 시 실제 재잠금 동작.
- 각 섹션 하단 회색 헬퍼 텍스트 존재.
- typecheck/lint/format 통과, #Preview로 시각 확인 가능.

## 진행 로그
(exec-plan-sync가 커밋마다 채운다)
