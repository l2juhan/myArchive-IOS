---
name: github-issue-create
description: "할 작업을 GitHub 이슈로 만든다. '이슈 만들어줘', '이걸 이슈로 등록해', '버그 이슈 올려줘', '이 작업 트래킹하게 이슈로' 같은 요청 시 트리거. 작업 성격에 맞는 .github/ISSUE_TEMPLATE/ 템플릿(feature/bug/design/refactor/test/chore)을 골라 그 형식·제목 접두사·라벨대로 초안을 만들어 사용자 승인 후 gh issue create로 생성한다. PRD 기능 ID(F-x)와 마일스톤(M1~M6)을 라벨로 연계한다."
---

# github-issue-create

작업을 추적 가능한 단위로 만들기 위해 GitHub 이슈를 생성한다. **이슈는 작업의 시작점**이고, 이후 github-issue-work가 이걸 읽어 exec-plan을 쓴다. 그래서 이슈 본문이 명확할수록 뒤 단계가 매끄럽다.

## 왜

말로 흘러간 작업은 추적·검증되지 않는다. 이슈로 박제하면 exec-plan·PR·머지까지 한 줄로 이어진다. 이슈 생성은 **외부로 나가는 행위**라 초안을 보여주고 승인받는다.

## 템플릿은 `.github/ISSUE_TEMPLATE/`를 따른다 (단일 소스)

본문 형식을 스킬이 임의로 정하지 않는다. 리포의 이슈 템플릿이 형식·제목 접두사·라벨의 **단일 소스**다. 작업 성격에 맞는 템플릿을 골라 그 구조 그대로 채운다.

| 작업 성격 | 템플릿 파일 | 제목 접두사 / 라벨 |
| --- | --- | --- |
| 새 기능 | `feature.md` | `[Feature] ` / `feature` |
| 버그 | `bug.md` | `[Bug] ` / `bug` |
| 화면·컴포넌트 UI | `design.md` | `[Design] ` / `design` |
| 리팩토링 | `refactor.md` | `[Refactor] ` / `refactor` |
| 테스트 추가/개선 | `test.md` | `[Test] ` / `test` |
| 설정·도구·의존성 | `chore.md` | `[Chore] ` / `chore` |

> 제목 접두사와 라벨은 각 템플릿의 frontmatter(`title`, `labels`)에서 그대로 읽어 쓴다. 추측하지 말고 파일을 열어 확인한다.

## 절차

1. **맥락 파악 + 템플릿 선택** — 사용자가 말한 작업의 성격으로 위 표에서 템플릿을 고른다. 모호하면 PRD(`docs/references/MyArchive_PRD_v0.5.md`)에서 관련 기능(F-x)·마일스톤(M1~M6)을 찾아 연결한다.
2. **템플릿 로드** — 해당 `.github/ISSUE_TEMPLATE/{type}.md`를 읽는다. frontmatter(`title`·`labels`)와 본문 섹션 구조를 그대로 가져온다.
3. **초안 작성** — 템플릿의 `<!-- 주석 -->` 안내를 실제 내용으로 대체한다. 코드/문서를 뒤져 화면·서비스명, `PRD ID`(F-x), 완료 기준을 정확히 채운다. **템플릿 섹션을 임의로 빼거나 추가하지 않는다.** 비는 섹션은 "해당 없음"으로 둔다.
4. **마일스톤 라벨 추가 제안** — 템플릿 기본 라벨에 더해 마일스톤이면 `M1`~`M6` 라벨을 제안한다. 리포에 없는 라벨은 `gh label create`도 함께 제안(승인 후).
5. **승인** — 제목·본문·라벨을 보여주고 승인을 받는다. 승인 전에는 생성하지 않는다.
6. **생성** — frontmatter는 제외하고 본문만 `--body`로 넘긴다: `gh issue create --title "[Feature] ..." --body ... --label feature,...`. 생성된 이슈 번호·URL을 보고한다.

## 규칙

- **템플릿 구조를 보존한다.** `.github/ISSUE_TEMPLATE/`가 바뀌면 이 스킬도 자동으로 새 형식을 따른다(파일을 매번 읽으므로).
- 이슈 본문에 "🤖 Generated with Claude Code" 같은 문구를 **넣지 않는다**(글로벌 규칙).
- 시크릿 평문·실제 비밀번호 값을 이슈에 넣지 않는다(로컬 전용 보안 앱).
- 한 이슈는 한 작업 단위로. 너무 크면 분리를 제안한다.
- 템플릿은 iOS(SwiftLint·xcodebuild·XCTest·라이트 모드 전용) 기준으로 정리돼 있다. 향후 RN/JS 표현이 끼어들면 채우면서 iOS 맥락으로 바로잡되 **섹션 구조 자체는 유지**한다.

## 다음 단계

생성 후 "이 이슈로 작업 시작하려면 `github #nn 작업해`"라고 안내한다 → github-issue-work로 이어진다.
