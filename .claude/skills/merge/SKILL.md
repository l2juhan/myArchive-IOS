---
name: merge
description: "문서 동기화를 확인하고 exec-plan을 지운 뒤 PR을 squash 머지한다. '머지해', 'merge', 'PR 머지해줘', '#nn 머지' 같은 요청 시 트리거. view-inventory 신선도와 doc-sync-map 상태를 확인하고, 해당 작업 exec-plan을 삭제한 뒤 사용자 승인을 받아 gh pr merge --squash로 머지하고 로컬을 정리한다."
---

# merge

작업을 `main`(통합 브랜치)에 합치고 흔적을 정리한다. 머지는 **되돌리기 어려운 외부 행위**라 동기화 확인 → exec-plan 삭제 → 승인(승인 게이트 5) → squash 순으로만 진행한다.

## 왜

머지 후엔 exec-plan이 역할을 다한다(작업이 main에 박혔으니). 남겨두면 다음 작업과 섞여 drift가 된다 — 그래서 머지 시 삭제한다. 머지 전에 문서가 어긋나면 main에 불일치가 박히므로 동기화를 먼저 확인한다.

## 절차

1. **PR 식별** — 번호 또는 현재 브랜치 PR. 리뷰 상태(`gh pr view nn --json reviews,mergeable`)와 CI/체크를 확인한다.
2. **동기화 확인**
   - `scripts/gen-view-inventory.sh`를 돌려 `docs/generated/view-inventory.md`와 diff가 없는지(신선도) 확인.
   - `.claude/doc-sync-map.json` 규칙으로 변경 코드 대비 누락 문서가 없는지 확인.
   - 어긋나면 머지를 멈추고 docs-sync를 먼저 권한다.
3. **exec-plan 삭제** — 이 작업의 `docs/exec-plans/{slug}.md`를 삭제하고 그 삭제를 커밋(또는 PR 브랜치에 반영)한다. squash에 포함되게 한다.
4. **승인(승인 게이트 5)** — 머지 방식(squash)·삭제할 exec-plan·대상 PR을 보여주고 승인받는다. 승인 전 머지하지 않는다.
5. **머지** — `gh pr merge nn --squash --delete-branch` 실행(base는 `main`). squash 커밋 메시지에 "🤖 Generated with Claude Code"·`Co-Authored-By:`를 **넣지 않는다**(글로벌 규칙).
6. **로컬 정리** — `git switch main && git pull && git branch -d <branch>`. 원격 브랜치는 `--delete-branch`로 정리됨. **로컬에 미커밋 변경이 있으면 머지 전에 커밋/스태시**해 후처리 checkout이 막히지 않게 한다.

## 규칙

- 동기화 미확인 상태로 머지하지 않는다(pre-push를 우회하지 않는 것과 같은 원칙).
- exec-plan 삭제는 머지의 일부다 — 빼먹으면 다음 작업의 pre-commit과 충돌한다.
- 머지 후 후속 작업이 있으면 github-issue-work로 새 사이클을 시작한다.
- 머지 도중 충돌·CI 실패 시 멈추고 사용자에게 보고한다.
