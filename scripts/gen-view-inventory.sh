#!/bin/bash
# SwiftUI View 인벤토리 생성 — docs/generated/view-inventory.md 의 단일 생성기.
# 코드에서 자동 생성하므로 손으로 고치지 않는다. pre-push가 이 출력과 커밋본을 대조해 신선도를 강제한다.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

echo "# View Inventory (자동 생성)"
echo ""
echo "> \`scripts/gen-view-inventory.sh\`가 생성한다. 직접 편집 금지. View를 추가/삭제하면 docs-sync가 재생성한다."
echo ""

emit_section() {
  local title="$1" dir="$2"
  echo "## $title"
  echo ""
  if [ -d "$dir" ]; then
    # 'struct Foo: View' 정의를 수집
    grep -rhoE 'struct [A-Za-z0-9_]+ *: *View' "$dir" 2>/dev/null \
      | sed -E 's/struct ([A-Za-z0-9_]+).*/- `\1`/' | sort -u
  fi
  echo ""
}

emit_section "App" "myArchive/App"
emit_section "Views — Lock" "myArchive/Views/Lock"
emit_section "Views — List" "myArchive/Views/List"
emit_section "Views — Detail" "myArchive/Views/Detail"
emit_section "Views — AddEdit" "myArchive/Views/AddEdit"
emit_section "Views — Settings" "myArchive/Views/Settings"
emit_section "Views — Components" "myArchive/Views/Components"

count=$(grep -rhoE 'struct [A-Za-z0-9_]+ *: *View' myArchive 2>/dev/null | sort -u | wc -l | tr -d ' ')
echo "---"
echo ""
echo "총 View 수: **$count**"
