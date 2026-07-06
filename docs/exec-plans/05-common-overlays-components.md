# 05 공통 오버레이·컴포넌트(토스트·삭제 모달)

- 이슈: #5  ·  PRD: 해당 없음 (Design.md 2.6 / 1.4 / 1.5)  ·  마일스톤: M1
- 상태: done

## 목표
전 화면이 재사용하는 공통 오버레이·컴포넌트를 `myArchive/Views/Components/`에 신설한다. 완료 시 토스트·삭제 확인 모달·커스텀 토글·칩이 Design.md 명세대로 렌더되고 각 `#Preview`로 시각 확인이 가능하며, 이미 존재하는 네이티브 `Toggle` 사용처(설정·추가/수정)가 커스텀 토글로 교체된다.

## 배경 / 현재 상태
- 디자인 토큰은 이미 전부 정의됨 — `MARadius.toast(14)/.modal(20)/.segment(7)`, `MAMotion.toast/.modal/.segment`, `MAColor.toastSurface/.toastSub/.success/.destructive/.toggleOff/.primary/.chipBG/.favChipBG/.favChipText`, `MAType.toastTitle/.toastSub`. → 이 작업은 토큰 소비만 하고 신규 토큰은 원칙적으로 만들지 않는다(부족 시 최소 추가).
- **세그먼트(`MASegmentedControl`)는 #4에서 이미 완료** — 이 이슈에선 재작성하지 않고 "공통 컴포넌트화 완료" 항목으로만 취급.
- 토스트·삭제 확인 모달 컴포넌트는 **아직 없음** → 신설.
- 토글은 현재 네이티브 `Toggle` 2곳 사용 중 — `SettingsView.swift:63`(앱 잠금), `AddEditView.swift:182`(즐겨찾기). Design.md는 커스텀 pill 토글(51×31, 노브 27, 켜짐 `#4647AE`, 꺼짐 `#CDD2DB`)을 요구 → 커스텀 `MAToggle` 신설 후 두 곳 교체.
- 칩은 상세 화면(#9, 미착수)의 즐겨찾기 토글 칩·타임스탬프 칩이 소비처 → 이 이슈에선 **컴포넌트 + #Preview까지만** 제공하고, 실제 화면 배선은 #9에서 한다.
- 토스트·삭제 모달의 실제 소비처(복사/저장/삭제 피드백 #13, 상세 삭제 #9)도 이후 마일스톤 몫 → 이 이슈는 **재사용 가능한 컴포넌트 + 표시 진입점(모디파이어/바인딩) 제공**까지가 범위.

## 범위 경계 (중요)
- **In**: 컴포넌트 4종 신설/정비(토스트·삭제 모달·커스텀 토글·칩) + 각 `#Preview` + 네이티브 `Toggle` 2곳 교체.
- **Out**: 복사/저장/삭제 등 실제 피드백 트리거 배선(→ #9·#13), 상세 화면 칩 실배선(→ #9). 여기선 소비처를 만들지 않는다(토글 교체는 예외 — 이미 존재하는 사용처라 회귀 없이 교체 가능).

## 작업 분해

### UI (myarchive-ui)
- [x] `MAToast` 신설 — 다크 카드 `toastSurface`, radius 14, 초록 체크 배지(`success`) + 제목(`toastTitle`)/서브(`toastSub`), 하단 48pt. 표시 진입점: `View.maToast(isPresented:title:subtitle:)` 모디파이어(등장 `MAMotion.toast`=translateY 14→0+opacity, 약 2.4s 후 자동 해제). 그림자 `0 12px 32px rgba(0,0,0,.28)`.
- [x] `MAConfirmDialog` 신설 — 반투명 딤 + 중앙 카드 radius 20, 제목/설명 + [취소 / 삭제(`destructive`)] 2버튼. 등장 `MAMotion.modal`(maFade .18s + 카드 maPop scale .93→1). 표시 진입점: 바인딩 기반(`isPresented` + `onConfirm`). 그림자 `0 24px 60px rgba(0,0,0,.32)`.
- [x] `MAToggle` 신설 — 51×31 pill, 노브 27, 켜짐 `primary`/꺼짐 `toggleOff`, 전환 `MAMotion.segment`(.15~.2s). `@Binding var isOn`.
- [x] `MAChip` 신설 — 상세용 칩. (a) 타임스탬프 칩: `chipBG` 배경. (b) 즐겨찾기 토글 칩: 활성 `favChipBG`/`favChipText`, 비활성 `chipBG`. 소비는 #9.
- [x] 네이티브 `Toggle` → `MAToggle` 교체: `SettingsView.swift`(앱 잠금), `AddEditView.swift`(즐겨찾기). 기존 바인딩/동작 유지.
- [x] 각 컴포넌트 `#Preview` 제공(토스트 표시 상태, 모달 표시 상태, 토글 on/off, 칩 활성/비활성).

### 검증 (myarchive-qa)
- [x] `swiftc -typecheck` 통과(신규 4파일 + 교체 2파일).
- [x] `swiftlint` 경고 없음 · `swiftformat --lint` 통과(0/29).
- [x] 토큰 소비 정합: 신규 하드코딩 HEX 없이 `MAColor`/`MARadius`/`MAMotion`/`MAType`만 사용.
- [x] `MAToggle` 교체 후 `isAppLockEnabled`·`isFavorite` 바인딩 타입 정합 확인.
- [ ] 실기기 시각·모션 확인 필요(사용자 핸드오프) — 시뮬레이터 금지.

## 의존성
1. UI 단독 작업(값 로직 없음). 컴포넌트 4종은 서로 독립 → 병렬 가능.
2. `MAToggle` 신설 → 네이티브 Toggle 2곳 교체(신설 완료가 선행).
3. 전부 완료 후 QA 교차 검증(토큰 정합 + 토글 교체 회귀).

## 완료 조건
- `MAToast`·`MAConfirmDialog`·`MAToggle`·`MAChip` 4종이 `Views/Components/`에 존재하고 각 `#Preview`로 렌더 확인 가능(라이트 모드 전용).
- 모션이 `MAMotion` 토큰(toast/modal/segment)으로 적용됨.
- 네이티브 `Toggle` 2곳이 `MAToggle`로 교체되고 기존 설정/즐겨찾기 동작이 유지됨.
- typecheck/lint/format 통과. 신규 하드코딩 색상 없음.
- (범위 밖) 토스트/모달/칩의 실제 화면 트리거 배선은 #9·#13에서 진행.

## 진행 로그
(exec-plan-sync가 커밋마다 채운다)
