---
name: docs-sync
description: "푸시 전 문서를 코드와 동기화한다. 푸시 직전, '문서 동기화해', '/docs-sync', '푸시 전에 문서 맞춰줘', 'view-inventory 갱신' 같은 상황에서 트리거. scripts/gen-view-inventory.sh로 view-inventory를 재생성하고, doc-sync-map.json 규칙으로 변경 코드 대비 갱신이 필요한 문서(DESIGN_SYSTEM/keychain-schema/ARCHITECTURE/PRD)를 diff 기반으로 점검·갱신한 뒤 커밋·푸시(승인)한다. pre-push 게이트와 짝이다."
---

# docs-sync

코드와 문서가 어긋난 채 원격으로 나가는 걸 막는다. **push 시점**의 워커로, pre-push 게이트(view-inventory 신선도 + doc-sync-map)와 짝이다. 게이트가 막기 전에 이 스킬이 문서를 맞춘다.

## 두 종류의 동기화 (강도가 다르다)

- **결정론 (generated, 기계 강제)** — `docs/generated/view-inventory.md`. 코드에서 자동 생성하므로 손으로 고치지 않는다. 재생성만 한다. pre-push가 코드와 diff해 어긋나면 **차단**.
- **판단 (글 문서, diff 기반)** — `DESIGN_SYSTEM.md`·`keychain-schema.md`·`ARCHITECTURE.md`·PRD. 코드 변경의 *의미*를 보고 사람/에이전트가 갱신한다. doc-sync-map은 "고쳐야 할 문서를 아예 안 건드린 것"만 잡는다(기본 경고).

## 절차

1. **view-inventory 재생성** — `scripts/gen-view-inventory.sh > docs/generated/view-inventory.md`. View 추가/삭제가 자동 반영된다. 직접 편집 금지.
2. **변경 코드 파악** — `git diff --name-only origin/<branch>..HEAD`(또는 `HEAD~1..HEAD`)로 무엇이 바뀌었는지 본다.
3. **doc-sync-map 규칙 적용** — `.claude/doc-sync-map.json`을 읽고 변경 패턴별로 짝 문서를 점검:
   - `myArchive/DesignSystem/**` → `docs/DESIGN_SYSTEM.md` (토큰 매핑)
   - `myArchive/Models/**`·`KeychainService.swift` → `docs/references/keychain-schema.md` (방식 B 키 규칙)
   - `myArchive/Views/**` → view-inventory(1번에서 처리, **block**)
   - `myArchive/ViewModels/**`·`App/**` → `docs/ARCHITECTURE.md` (MVVM·경계·진입 흐름)
   - `docs/references/MyArchive_PRD_v0.5.md` → 상위 폴더 핸드오프 사본 동기화
4. **diff 기반 갱신** — 점검에서 걸린 글 문서를 실제 변경 내용에 맞게 갱신한다. 바뀐 게 없으면 두지 않는다(과잉 갱신 금지).
5. **누락 점검** — pre-push를 미리 모사: `scripts/gen-view-inventory.sh`를 다시 돌려 커밋본과 diff가 없는지, 경고가 남지 않았는지 확인.
6. **커밋·푸시(승인)** — 문서 변경을 커밋하고 **사용자 승인 후** 푸시한다(승인 게이트 3 흐름). 승인 없이 push하지 않는다.

## 규칙

- view-inventory는 절대 손으로 고치지 않는다 — 항상 생성기로.
- PRD를 고쳤으면 상위 핸드오프 사본도 맞춘다(양방향).
- 시크릿 키 *규칙*은 keychain-schema에 적되 실제 시크릿 값은 적지 않는다.
- `--no-verify`로 pre-push를 우회하지 않는다.

## 다음 단계

문서 동기화가 끝나면 pr-create로 PR 초안을 만든다(품질 점수 선행).
