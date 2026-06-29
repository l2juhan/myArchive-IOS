---
description: docs-sync 스킬을 실행해 view-inventory를 재생성하고 doc-sync-map 짝 문서를 점검·갱신한다.
---

`docs-sync` 스킬을 직접 실행한다. push 시점의 문서 동기화 워커로, pre-push 게이트(view-inventory 신선도 + doc-sync-map)와 짝이다.

## 실행

`docs-sync` 스킬을 호출해 다음을 수행한다:

1. **view-inventory 재생성** — `scripts/gen-view-inventory.sh > docs/generated/view-inventory.md`. 손으로 고치지 않고 생성기로만.
2. **변경 코드 파악** — `git diff --name-only origin/<branch>..HEAD`(또는 `HEAD~1..HEAD`).
3. **doc-sync-map 점검·갱신** — `.claude/doc-sync-map.json` 규칙으로 변경 패턴별 짝 문서(`DESIGN_SYSTEM.md`·`keychain-schema.md`·`ARCHITECTURE.md`·PRD)를 diff 기반으로 갱신. 바뀐 게 없으면 두지 않는다.
4. **누락 점검** — pre-push를 모사해 view-inventory diff·경고가 남지 않는지 확인.

커밋·푸시는 **사용자 승인 후**에만 한다. `--no-verify`로 게이트를 우회하지 않는다.
