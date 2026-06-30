# myArchive — 하네스 규칙

마이아카이브(myArchive)는 빠르고 가벼운 **로컬 전용 iOS 비밀번호 관리 앱**이다. 이 문서는 *무엇을/왜*가 아니라 **하네스가 어떻게 동작하는지** — 어떤 문서가 어떤 작업의 기준인지, 어디서 사용자 승인을 받는지를 정의한다.

- 제품 요구사항(*무엇을/왜*): `docs/references/MyArchive_PRD_v0.5.md`
- 시각 명세(*어떻게 보이고 동작*): `docs/references/Design.md`
- 기술 스택: Swift · SwiftUI · iOS 17+ · SwiftData(메타) · Keychain(시크릿, 방식 B) · LocalAuthentication · MVVM · SPM. **외부 라이브러리 없이 Apple 표준 프레임워크만 사용.**

> 문서를 알아서 다 읽기를 기대하지 않는다. 작업에 맞는 문서를 아래 매니페스트에서 골라 읽는다.

## 개발자 배경 (커뮤니케이션 톤)

개발자는 **TypeScript + React Native 경험이 있으나 Xcode·Swift는 처음**이다. 따라서:
- Swift/SwiftUI/Xcode 고유 개념은 **RN/TS에 빗대어** 설명한다 (예: `@State`≈`useState`, SwiftUI `View`≈함수형 컴포넌트, SwiftData≈ORM, `@AppStorage`≈AsyncStorage). 옵셔널·ARC·프로퍼티 래퍼·스킴/타깃/서명 등은 처음이므로 짚어준다.
- Xcode IDE 워크플로(시뮬레이터·스킴·Archive)는 GUI 위치까지 구체적으로 안내한다.
- 일반 프로그래밍·앱 아키텍처는 이미 익숙하므로 기초 반복은 생략하고 **Swift만의 차이에 집중**한다.

---

## docs/ 매니페스트

- `docs/references/MyArchive_PRD_v0.5.md` — **제품 요구사항(1차 자료)**. 상위 폴더 핸드오프 사본. 변경 시 양쪽 동기화.
- `docs/references/Design.md` — **시각 명세(1차 자료)**. 색·타이포·간격·라운드·모션·화면 레이아웃·상태 전이의 단일 소스.
- `docs/references/MyArchive_Design_Indigo.html` — 인터랙티브 디자인 레퍼런스(동작 확인용, 이식 금지).
- `docs/references/screenshots/` — 화면별 캡처(01~05).
- `docs/references/keychain-schema.md` — **데이터 모델 + Keychain 키 규칙(방식 B)의 1차 자료**. 모델·시크릿 저장 작업 시 먼저 읽는다.
- `docs/ARCHITECTURE.md` — 코드 컨벤션·MVVM·폴더 경계(UI/Logic 분리).
- `docs/DESIGN_SYSTEM.md` — DesignSystem 토큰 ↔ Design.md 매핑. UI 토큰 변경 시 동기화.
- `docs/swift-code-quality.md` — 가독성·예측성·응집도·결합도 품질 기준.
- `docs/PR-writing-guide.md` — PR 본문 톤 가이드(pr-create가 따름, `.github/pull_request_template.md`와 짝).
- `docs/folder-structure.md` — 확정 폴더 구조.
- `docs/TESTING.md` — 단위 테스트 가이드(대상·예시·우선순위).
- `docs/DEPLOY.md` — Archive / TestFlight 배포 가이드.
- `docs/QUALITY_SCORE.md` — 품질 등급 추적(/quality가 관리, 동기화 대상 아님).
- `docs/design-docs/core-beliefs.md` — 프로젝트 설계 철학(스킬이 판단 시 참조).
- `docs/design-docs/feedback-log.md` — 피드백·교정 이력 + /health 발견 문제.
- `docs/generated/view-inventory.md` — SwiftUI View 목록(**자동 생성, 손으로 고치지 않음**).
- `docs/exec-plans/` — 이슈별 작업 계획(자동 생성, 머지 시 삭제).

**현재 작업: `docs/exec-plans/` 참조.**

---

## 에이전트 & 실행 모드

작업은 **에이전트 팀**(기본)으로 처리한다. 오케스트레이터(`myarchive-orchestrator` 스킬)가 팀을 구성·조율한다.

- `myarchive-ui` — SwiftUI 화면·컴포넌트·디자인 토큰.
- `myarchive-logic` — SwiftData·Keychain·인증·클립보드·정렬/검색·ViewModel.
- `myarchive-qa` — 빌드/lint/테스트 실행 + 경계면 교차 검증(`/review`, 재시도 2회).

UI는 표시만, 값 처리는 Logic으로 모은다(경계 분리). 경계면(메타↔Keychain↔UI) 정합성은 QA가 교차 검증한다.

---

## 시간축 — 시점마다 훅(게이트) + 스킬(워커) 한 쌍

| 시점 | 게이트(훅) | 워커(스킬) |
| --- | --- | --- |
| **edit** | PostToolUse: SwiftFormat + SwiftLint 자동 교정 | (편집은 ui/logic 에이전트) |
| **commit** | pre-commit: exec-plan 스테이징 검사 | exec-plan-sync — 진행을 계획에 반영 |
| **review** | — | QA 서브에이전트 · `/review` |
| **push** | pre-push: view-inventory 신선도 + doc-sync-map | docs-sync — 문서 동기화 |
| **pr** | (`/quality` 선행) | pr-create · pr-review-check |
| **merge** | — | merge — 동기화 확인 + exec-plan 삭제 + squash |

훅은 `.githooks/`(git `core.hooksPath`)와 `.claude/settings.json`(PostToolUse/PreToolUse)에 정의된다.

---

## 승인 게이트 (사용자 확인 필요 지점)

다음 지점에서는 **반드시 사용자 승인**을 받고 진행한다. 그 외 편집·교정은 자동.

1. **계획 확정** — github-issue-work가 exec-plan을 쓴 뒤, 마음에 들 때까지 다듬고 승인.
2. **정리 보고** — 구현·QA 통과 후 작업 내용을 정리해 보고하고 승인.
3. **푸시/PR 초안** — docs-sync 후 pr-create가 PR 초안을 만들어 검토 요청, 승인.
4. **PR 생성** — `gh pr create` 실행 전 승인.
5. **머지** — `gh pr merge --squash` 실행 전 승인.

커밋·푸시·PR·머지 같은 외부로 나가거나 되돌리기 어려운 행위는 명시 승인 없이 실행하지 않는다.

---

## 분기 전략

**main 단일 통합 브랜치**를 쓴다(1인 프로젝트).

- **`main`** — 통합 겸 배포 기준 브랜치. 기능 작업 브랜치(`feature/...`, `fix/...`, `chore/...`)는 `main`에서 분기하고 PR의 **base는 `main`**.
- pr-create는 base를 `main`으로, merge는 `main`으로 squash 머지한다. CI(`.github/workflows/test.yml`)는 `main`의 push/PR에서 돈다.
- 릴리스는 `main`에서 태그(`v1.0` 등)로 표시한다.

---

## 문서 동기화 강도

- **결정론(기계 강제)**: `docs/generated/view-inventory.md`는 docs-sync가 재생성하고 pre-push가 코드와 대조해 신선도를 강제. exec-plan 스테이징은 pre-commit이 강제.
- **판단(diff 기반 갱신)**: `ARCHITECTURE.md`·`DESIGN_SYSTEM.md`·`keychain-schema.md`·PRD·exec-plan 내용은 docs-sync/exec-plan-sync가 diff를 보고 갱신. 게이트는 "고쳐야 할 문서를 아예 안 건드린 것"만 doc-sync-map으로 잡는다(기본 경고, 늘 맞는 규칙은 차단).
- **대상 외**: `QUALITY_SCORE.md`·`core-beliefs.md`·`feedback-log.md`는 /quality·harness-feedback이 따로 관리.

---

## 프로젝트 생성

`.xcodeproj`는 **XcodeGen이 단일 소스(`project.yml`)에서 생성**한다(git 비추적). 소스/설정 변경 후 `xcodegen generate`로 재생성한다. iOS 17.0 타깃, 라이트 모드 전용, 번들 ID `com.l2juhan.myArchive`.

---

## 테스트·빌드 정책 — **실기기 전용 (시뮬레이터 금지)**

> 이 프로젝트의 동작 테스트는 **반드시 실기기(physical iOS device)로만** 한다. 어떤 에이전트·스킬·세션도 **iOS 시뮬레이터 빌드/실행/테스트를 시도하지 않는다.** (사용자 결정 — 시뮬레이터로 테스트하지 말 것.)

- **기계 검증(에이전트/QA가 헤드리스로 하는 것)**: `swiftc -typecheck`(컴파일 정합성) + `swiftlint` + `swiftformat --lint` 까지만. **`xcodebuild`로 시뮬레이터 destination을 enumerate·빌드·`test` 하지 않는다.** `platform=iOS Simulator` destination, `-sdk iphonesimulator` 빌드, CoreSimulator 재시작 등 시뮬레이터 복구 시도도 금지.
- **런타임·시각·동작 검증(실행이 필요한 것)**: **실기기**에서 사람이 Xcode로 수행한다(`▶ Run`/`⌘R`, destination = 연결된 iPhone). 빠른 시각 확인은 Xcode Canvas `#Preview`를 보조로 쓴다. QA는 여기까지 자동화하지 말고, 타입체크/lint 통과 후 "실기기 확인 필요" 항목으로 사용자에게 핸드오프한다.
- **단위 테스트(`myArchiveTests`)** 도 실기기 destination(`platform=iOS,name=<연결된 기기>` 또는 `generic/platform=iOS`)으로 돌린다. 시뮬레이터 destination을 쓰지 않는다.
- 배경: 로컬 Xcode가 신형 SDK(예: iOS 26.x) 기준이라 iOS 17 시뮬레이터 런타임이 없어 시뮬 빌드가 불안정하게 막힌다. 이를 우회하려 시뮬레이터를 깔거나 복구하는 대신 **실기기로만 간다.** 관련 함정은 메모리 `xcodegen-build-env`에 기록.
