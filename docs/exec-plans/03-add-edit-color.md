# 03 추가/수정 화면 + 색상 선택(F-15)

- 이슈: #3  ·  PRD: F-1, F-15  ·  마일스톤: M1
- 상태: done

## 목표
추가/수정 화면(AddEditView)을 Design.md 2.4대로 완성한다. 골격 상태의 화면을 5개 섹션
(기본 정보 · 색상 그리드 · 필드 · 추가 정보 · 즐겨찾기)으로 채우고, F-15 색상 선택(9색 프리셋 +
네이티브 커스텀 피커)과 커스텀 필드 인라인 추가/삭제가 동작하게 한다. 저장 시 시크릿(비밀번호·
커스텀 값)은 Keychain, 메타는 SwiftData(방식 B)로 나눠 저장하고 빈 커스텀 항목은 폐기한다.

## 작업 분해

### Logic (myarchive-logic)
- [x] `AddEditViewModel`(ViewModels/) 신설 — 드래프트 상태 소유. RN으로 치면 폼 상태 훅.
  - 필드: serviceName, username, password, colorHex, urlString, memo, isFavorite, fields(초안 배열).
  - 초안 커스텀 필드 타입(`DraftField`: id, label, value) — SwiftData 모델과 분리한 인메모리 구조.
  - `isValid`: serviceName 비면 false(트림 기준).
  - `init(editing:)` — 편집 대상에서 메타 + Keychain 시크릿(비밀번호·각 커스텀 값) 로드(sortOrder 순).
  - `addField()` / `removeField(_:)` — 초안 배열 인라인 조작.
  - `save(context:) -> Bool` — 방식 B 저장. 신규/편집 분기, updatedAt 갱신, 색상 폴백 처리. Keychain 저장 성공 여부 반환(@discardableResult).
- [x] 저장 규칙(Design.md 3.7):
  - 라벨·값 **모두 빈** 커스텀 항목은 저장에서 폐기.
  - 편집 시 초안에서 사라진 커스텀 필드는 SwiftData·Keychain(valueRef)에서 제거.
  - 색상 미선택(빈 값) 시 `MAAvatarPalette.fallbackHex(for: serviceName)` 폴백.
- [x] 커스텀 필드 시크릿은 `KeychainService.valueRef(for:)` 키로 저장/삭제. 평문은 SwiftData에 남기지 않음.

### UI (myarchive-ui)
- [x] `AddEditView` 재구성 — 헤더(취소/타이틀/저장) + 5개 섹션. ViewModel(`@State`로 소유) 바인딩.
  - 저장 버튼: 유효 시 `#6D94C5`(interactiveText) 활성, 비활성 시스템 disabled 톤.
  - 저장 실패 시 dismiss 금지 + `.alert` 안내(QA FIX-1 반영).
- [x] 색상 섹션 컴포넌트(`ColorPickerGrid`, Components/) — 9색 프리셋 원형 30px 그리드 + 네이티브
  컬러 피커(무지개 스와치). 선택 시 링+체크, 밝은 색(#FFFFFF·#FEE500)은 잉크 체크
  (`MAAvatarPalette.foreground(on:)` 재사용). `Color.toHex()`(Color+Hex.swift) 추가로 커스텀 색 저장.
- [x] 커스텀 필드 행 컴포넌트(`CustomFieldRow`, Components/) — 라벨(점선 밑줄) · 값(모노) · 제거(−)
  원형 버튼(`destructiveBG #FDECEC`/`destructive #E5484D`). 카드 하단 '+ 필드 추가' 점선 버튼.
- [x] 비밀번호 필드 표시·숨김 토글(우측 표시/숨김 버튼).
- [x] 추가 정보 섹션: URL · 메모(textarea) / 즐겨찾기 토글(켜짐 `#4647AE`, 꺼짐 토큰 `#CDD2DB`).
- [x] `#Preview` — 신규/편집 두 케이스.

### 검증 (myarchive-qa)
- [x] `swiftc -typecheck`(iOS 타깃, EXIT=0) + swiftlint(0 violations) + swiftformat --lint(0 재포맷) 통과. 시뮬레이터 빌드 안 함.
- [x] 경계 교차 검증: 저장 후 메타(SwiftData) ↔ 시크릿(Keychain) ↔ 초안 정합. 빈 커스텀 폐기·삭제 필드 Keychain 정리·색상 폴백·시크릿 평문 미누출 모두 PASS.
- [ ] 실기기 확인 필요 항목 핸드오프(색상 선택 링/체크·컬러 피커 왕복·커스텀 인라인·저장 왕복). — 사람 몫으로 잔여.

## 의존성
`AddEditViewModel` API(필드·`addField`/`removeField`/`save`) 확정 → UI가 바인딩 →
컴포넌트(ColorPickerGrid·CustomFieldRow) → QA 교차 검증. Logic 선행.

## 완료 조건
- 라이트 모드 전용(v1).
- 9색 프리셋 + 커스텀 피커 동작, 미지정 시 서비스명 해시 폴백.
- 커스텀 필드 인라인 추가/삭제 동작, 저장 시 빈 항목 폐기 + 삭제 필드 Keychain 정리.
- 서비스명 비면 저장 비활성.
- 방식 B 준수: 비밀번호·커스텀 값 평문이 SwiftData에 없음(Keychain 참조만).
- `#Preview`로 시각 확인 가능(신규·편집).

## 진행 로그
- 2026-07-06: 이슈 #3 구현 완료(에이전트 팀). Logic(AddEditViewModel+DraftField, 방식 B 저장) → UI(AddEditView 재작성 + ColorPickerGrid + CustomFieldRow) → QA 교차 검증(PASS). QA FIX-1(저장 실패 시 조용히 dismiss) 반영. 신규 파일 반영 위해 `xcodegen generate` 재실행(Xcode 타깃 멤버십 등록). 서명 Team ID(4XTGL2D5GF)를 project.yml에 영구 반영.
  - 변경 파일: myArchive/ViewModels/AddEditViewModel.swift, myArchive/Views/AddEdit/AddEditView.swift, myArchive/Views/Components/ColorPickerGrid.swift, myArchive/Views/Components/CustomFieldRow.swift, myArchive/DesignSystem/Color+Hex.swift, myArchive/DesignSystem/MAColor.swift, docs/DESIGN_SYSTEM.md, project.yml
- 2026-07-06: (범위 밖 동반 수정) 홈 목록 화면 CredentialListView 레이아웃 버그 2건 수정 — ① 헤더 겹침: 수동 headerHeight 측정을 safeAreaInset(.top)로 재구성, ② 검색 0건 시 키보드 사라짐: 본문 최상위를 ScrollView로 고정 + scrollDismissesKeyboard(.never). 실기기 테스트 중 발견됨.
  - 변경 파일: myArchive/Views/List/CredentialListView.swift
