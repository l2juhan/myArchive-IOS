---
name: github-issue-work
description: "GitHub 이슈를 읽어 작업 계획(exec-plan)을 세운다. 'github #nn 작업해', '이슈 nn 진행해', '이슈 nn 시작', '이거 작업 계획 세워줘' 같은 요청 시 트리거. 이슈와 관련 문서를 읽고 docs/exec-plans/{slug}.md에 목표·UI/Logic/검증 작업 분해·의존성·완료 조건을 쓴 뒤, 사용자가 만족할 때까지 다듬는다(승인 게이트 1). 승인되면 myarchive-orchestrator로 넘긴다."
---

# github-issue-work

이슈를 **실행 가능한 작업 계획(exec-plan)**으로 바꾼다. 이 스킬의 산출물은 코드가 아니라 `docs/exec-plans/{slug}.md` 한 장이다. 구현은 그다음 myarchive-orchestrator가 한다.

## 왜

곧장 구현하면 범위가 흐트러지고 경계(UI/Logic)가 섞인다. 계획을 먼저 합의하면 팀이 분담·검증할 기준이 생긴다. exec-plan은 commit 시점에 pre-commit이 스테이징을 강제하는 **하네스의 중심 문서**다(코드만 커밋되는 drift 방지).

## 절차

1. **이슈 로드** — `gh issue view nn --comments`로 이슈 본문·라벨·코멘트를 읽는다.
2. **관련 문서 선별** — CLAUDE.md `docs/ 매니페스트`에서 **이 작업에 필요한 문서만** 고른다. 전부 읽지 않는다.
   - 화면 작업 → `Design.md`, `DESIGN_SYSTEM.md`
   - 모델·시크릿 → `keychain-schema.md`, `myarchive-domain` 스킬
   - 구조·흐름 → `ARCHITECTURE.md`, `folder-structure.md`
   - 무엇/왜 → PRD 해당 절(F-x)
3. **exec-plan 작성** — `docs/exec-plans/{slug}.md`에 아래 템플릿으로 쓴다. slug는 `nn-짧은-제목`.
4. **다듬기(승인 게이트 1)** — 사용자에게 보여주고 마음에 들 때까지 수정한다. 범위·완료 조건·작업 분해가 합의될 때까지 반복. 승인 없이 구현으로 넘어가지 않는다.
5. **핸드오프** — 승인되면 myarchive-orchestrator로 넘긴다(Phase 0이 이 exec-plan을 로드).

## exec-plan 템플릿

```
# {nn} {제목}

- 이슈: #nn  ·  PRD: F-x  ·  마일스톤: M-x
- 상태: planning

## 목표
한두 문장. 완료 시 무엇이 동작하는가.

## 작업 분해
### UI (myarchive-ui)
- [ ] ...
### Logic (myarchive-logic)
- [ ] ...
### 검증 (myarchive-qa)
- [ ] ...

## 의존성
보통 Logic API 시그니처 → UI → QA. 구체적 선후를 적는다.

## 완료 조건
- 관찰 가능한 기준
- 도메인 규칙 충족(방식 B·마스킹·복사 만료·정렬 등 해당 시)

## 진행 로그
(exec-plan-sync가 커밋마다 채운다)
```

## 규칙

- UI는 표시, Logic은 값 처리로 **경계를 분리**해 작업을 나눈다(CLAUDE.md).
- 시크릿 평문은 어디에도 적지 않는다.
- 계획은 lean하게. 과도하게 잘게 쪼개지 않는다.
