# 09 상세 화면 레이아웃

- 이슈: #9  ·  PRD: F-3 (연관 F-4·F-6)  ·  마일스톤: M1
- 상태: done

## 목표
상세 화면(`CredentialDetailView`)을 Design.md 2.3 명세대로 **레이아웃·구조까지** 마감한다.
헤더(목록/편집) · 아이덴티티(아바타62·서비스명·URL·칩2) · 필드 카드(순서·라벨·값·복사 버튼·헤어라인) · 하단 계정 삭제 버튼 + 푸터 캡션을 갖춘다.
**시크릿 표시 동작(눈 아이콘 탭 → 블러 해제 · 22초 재마스킹)과 실제 복사 동작(클립보드·토스트)은 M5(F-3·F-4) 범위로 남긴다** — 이번엔 블러는 정적으로 걸고 복사 버튼은 배치까지.

## 배경 / 현재 상태
- `CredentialDetailView.swift`는 **골격만** 존재: 아바타 + 서비스명 + 타임스탬프 + "M3/M5에서 구현" 플레이스홀더.
- 재사용 자원이 이미 대부분 준비돼 있음:
  - 컴포넌트: `AvatarView(initial:colorHex:size:)`, `MATimestampChip(text:)`, `MAFavoriteChip(isOn:)`, `MAConfirmDialog(isPresented:title:message:onConfirm:)`.
  - 서비스: `KeychainService.get` (시크릿 조회), `CredentialStore.delete` (계정 삭제 정합성, #23 완료), `ClipboardService.copy` (M5 F-4용).
  - 토큰: `MAType.detailTitle/fieldLabel/fieldValue/secretValue/caption`, `MARadius.detailAvatar(17)/copyButton(10)`, `MAColor.interactiveText(#6D94C5)/accent(#FF5722)/copyButtonBG/success/destructive/fieldLabel/caption` — **신규 토큰 추가 거의 불필요.**
- 진입/편집: `CredentialListView`가 `navigationDestination(for: UUID.self)`로 상세 진입. 편집은 `AddEditView(editing:)` sheet 패턴 재사용.
- 경계: Views는 Keychain을 직접 호출하지 않는다(구조검사 경고) → **시크릿 조회는 ViewModel(logic) 경유.**

## 작업 분해

### Logic (myarchive-logic)
- [x] `DetailViewModel` (`myArchive/ViewModels/DetailViewModel.swift`) 신설, `@Observable`.
  - 표시 시점 시크릿 조회: `password = KeychainService.get(credential.passwordRef)`, 각 커스텀 필드 값 `KeychainService.get(field.valueRef)` (PRD 6.1 표시 시 조회).
  - 상세 필드 순서 모델 노출: 아이디 → 비밀번호 → 커스텀(sortOrder) → URL → 메모. 시크릿/비시크릿 여부 플래그 포함.
  - `delete(context:)` → `CredentialStore.delete` 위임 (Views가 Store 직접 호출하지 않도록 경유).
  - (M5 대비) 복사 API 자리만 정의하되 이번엔 배치까지 — 실제 `ClipboardService.copy` 배선은 F-4에서.

### UI (myarchive-ui)
- [x] `CopyButton` 컴포넌트 (`myArchive/Views/Components/CopyButton.swift`) 신설: 38×38 radius10, `copyButtonBG` 바탕 + 복사 아이콘(`accent` 스트로크). 액션은 주입받는 클로저(이번엔 no-op/배치, 복사 후 초록 체크 전이는 M5).
- [x] `DetailFieldRow` (View 내부 private struct): 라벨(`fieldLabel` 12/600) + 값 + 우측 복사 버튼. 시크릿 값은 `.blur(radius: 5)` + 우측 눈(eye) 힌트 아이콘(정적). URL은 `interactiveText` 링크색·블러 없음, 메모는 본문·블러 없음.
- [x] `CredentialDetailView` 재구성:
  - 헤더: 좌 '‹ 목록'(NavigationStack 기본 back, 틴트 `interactiveText`) · 우 '편집' 버튼 → `AddEditView(editing:)` sheet.
  - 아이덴티티(중앙): 아바타 62 → 서비스명 `detailTitle` → (있으면) URL 14/500 링크 → 칩 2개(`MAFavoriteChip`·`MATimestampChip`).
  - 필드 카드(흰, radius16): 순서대로 행 + 0.5px 헤어라인. 빈 값 행 생략.
  - 하단: '계정 삭제' 풀폭 흰 카드 버튼(텍스트 `destructive`) → `MAConfirmDialog` → 확인 시 `vm.delete` + `dismiss`.
  - 푸터 캡션: "비밀번호와 민감 필드는 기기 Keychain에 암호화 저장됩니다".
- [x] `#Preview` 2종: 풍부한 계정(즐겨찾기·URL·메모) / 최소 계정.

### 검증 (myarchive-qa)
- [x] `swiftlint` 0 violations.
- [x] `swiftformat --lint` 0/3 files require formatting.
- [x] `structure-check.sh` OK — Views에서 KeychainService.get/set 직접 호출 0건 확인.
- [x] 필드 순서(아이디→비번→커스텀→URL→메모) · 복사 버튼 배치 명세 일치.
- [x] 하드코딩 색/치수 없음(모든 토큰 확인).
- [ ] 실기기 시각·동작 확인 필요 (사용자 핸드오프).

## 의존성
1. Logic: `DetailViewModel` 시그니처(조회된 필드 리스트·삭제 API) 확정 → 2. UI: `CopyButton`/`DetailFieldRow` → `CredentialDetailView` 재구성이 VM 소비 → 3. QA 교차 검증(경계·순서·토큰).

## 완료 조건
- 헤더/아이덴티티/필드 카드/삭제 버튼/푸터가 2.3 · 03-detail.png와 일치(라이트 모드 전용).
- 필드 순서와 복사 버튼 배치가 명세대로. 시크릿은 블러(정적) + 눈 힌트.
- 시크릿 조회가 ViewModel 경유(구조검사 통과), 삭제가 `CredentialStore.delete` 경유.
- 토큰 사용·하드코딩 없음, #Preview로 시각 확인 가능.
- typecheck/lint/format/structure 통과.

## 범위 밖 (M5 / 별도 이슈)
- 눈 아이콘 탭 → 블러 해제, 이탈·22초 재마스킹 (F-3).
- 복사 버튼 실제 클립보드 복사 + 초록 체크 전이 + 토스트 + 만료 (F-4).

## 진행 로그
(exec-plan-sync가 커밋마다 채운다)
