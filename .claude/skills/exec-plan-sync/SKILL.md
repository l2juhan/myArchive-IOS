---
name: exec-plan-sync
description: "작업 진행을 exec-plan에 반영한다. 커밋 직전, '진행 반영해', '계획 업데이트해', '커밋하기 전에 정리', '/exec-plan-sync' 같은 상황에서 트리거. 완료/진행중 항목을 체크하고 변경 파일을 진행 로그에 기록한 뒤, exec-plan을 코드와 함께 스테이징한다. pre-commit이 exec-plan 스테이징을 강제하므로 commit 시점의 짝 스킬이다."
---

# exec-plan-sync

코드와 계획이 따로 노는 drift를 막는다. **commit 시점**의 워커로, pre-commit 게이트(exec-plan 스테이징 검사)와 짝이다. 코드만 커밋되고 계획이 안 따라오면 pre-commit이 커밋을 막는다 — 이 스킬이 그 전에 계획을 맞춘다.

## 왜

exec-plan은 "지금 어디까지 됐는가"의 단일 소스다. 커밋마다 갱신해야 PR·머지·리뷰가 신뢰할 수 있는 상태를 본다. 게이트가 강제하므로 빼먹으면 커밋 자체가 안 된다.

## 절차

1. **현재 exec-plan 찾기** — `docs/exec-plans/`에서 진행 중 계획을 연다(보통 1개). 여러 개면 이번 변경과 맞는 것을 고른다.
2. **변경 파일 확인** — `git status --short`와 `git diff --cached --name-only`로 이번에 무엇이 바뀌었는지 본다.
3. **항목 체크** — 완료된 작업은 `- [x]`로, 진행 중은 그대로 두되 진행 로그에 메모한다. 상태 필드(`planning`→`in-progress`→`done`)도 갱신한다.
4. **진행 로그 추가** — `## 진행 로그`에 한 줄 추가:
   ```
   - YYYY-MM-DD: {무엇을 했나} — 변경 파일: path/A.swift, path/B.swift
   ```
5. **스테이징** — 갱신한 exec-plan을 `git add docs/exec-plans/{slug}.md`로 코드와 함께 스테이징한다. 이래야 pre-commit을 통과한다.
6. **확인** — 커밋은 사용자 승인 흐름을 따른다. 이 스킬은 스테이징까지만 책임진다.

## pre-commit과의 관계

- 코드(`myArchive/**.swift`) 변경이 있는데 exec-plan이 스테이징 안 되면 → pre-commit이 **차단**한다.
- 즉 이 스킬을 돌리면 그 차단을 사전에 해소한다. 차단을 우회하려 `--no-verify`를 쓰지 않는다.

## 규칙

- **판단 기반 갱신**: 진행 반영은 기계가 아니라 diff를 보고 사람/에이전트가 판단한다(결정론 문서인 view-inventory와 다름).
- 시크릿 평문·실제 값을 진행 로그에 적지 않는다.
- 새 기능 작업이라 exec-plan이 없으면 먼저 github-issue-work로 계획을 세운다.
- exec-plan은 머지 시 merge 스킬이 삭제한다 — 여기서 지우지 않는다.
