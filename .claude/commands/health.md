---
description: 하네스 정합성을 점검(에이전트·스킬·훅·매니페스트·git hooksPath·view-inventory 신선도·도구 설치)하고 발견 문제를 feedback-log에 기록한다.
---

하네스 자체의 건강 상태를 점검한다. **이 브랜치에서는 발견 문제를 고치지 않는다** — 작업 브랜치를 오염시키지 않기 위해, 발견은 `docs/design-docs/feedback-log.md`에 기록만 하고 별도로 정비한다.

## 점검 항목

1. **에이전트 정합성** — `.claude/agents/`의 에이전트(`myarchive-ui`/`logic`/`qa`)가 frontmatter(`name`, `description`, 필요 시 `model`)를 갖췄는지, CLAUDE.md의 팀 구성과 일치하는지.
2. **스킬 정합성** — `.claude/skills/*/SKILL.md`가 `name`·`description`을 갖췄고, 시간축(commit/push/pr/merge) 워커가 빠짐없이 있는지.
3. **커맨드 정합성** — `.claude/commands/*.md`가 frontmatter(`description`)를 갖췄는지.
4. **훅** — `.githooks/pre-commit`·`pre-push` 실행권한(+x), `.claude/settings.json`의 PostToolUse/PreToolUse 훅 스크립트 존재·실행권한.
5. **git hooksPath** — `git config core.hooksPath`가 `.githooks`를 가리키는지.
6. **매니페스트 정합성** — CLAUDE.md docs/ 매니페스트에 적힌 문서가 실제로 존재하는지, `.claude/doc-sync-map.json`의 경로가 유효한지.
7. **view-inventory 신선도** — `scripts/gen-view-inventory.sh` 출력과 `docs/generated/view-inventory.md`가 일치하는지(diff).
8. **도구 설치** — `swiftlint`·`swiftformat`·`xcodegen`·`xcodebuild`가 PATH에 있는지.

## 보고 및 기록

- 항목별 OK / 경고 / 실패로 요약 보고한다.
- 발견된 문제는 `docs/design-docs/feedback-log.md`에 그 형식(`## [날짜] 제목` / 유형 `health 발견` / 관찰 / 제안 / 상태 `open`)으로 **추가**한다.
- **이 브랜치에서 수정하지 않는다.** feedback-log 기록 외 코드·설정 변경 금지.
