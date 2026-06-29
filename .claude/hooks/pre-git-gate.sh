#!/bin/bash
# PreToolUse 훅 — Claude Code가 git commit/push를 실행하기 직전 가로채는 게이트.
# .githooks의 검사를 호출해, 통과 못 하면 비0 종료로 도구 실행을 막는다.
# stdin으로 훅 JSON(tool_input.command)을 받는다.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

payload=$(cat)
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')
else
  cmd=$(printf '%s' "$payload" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
fi

case "$cmd" in
  *"git commit"*)
    if [ -x "$ROOT/.githooks/pre-commit" ]; then
      "$ROOT/.githooks/pre-commit" || { echo "[pre-git-gate] pre-commit 검사 실패 — 커밋을 막습니다." >&2; exit 2; }
    fi
    ;;
  *"git push"*)
    if [ -x "$ROOT/.githooks/pre-push" ]; then
      "$ROOT/.githooks/pre-push" || { echo "[pre-git-gate] pre-push 검사 실패 — 푸시를 막습니다." >&2; exit 2; }
    fi
    ;;
esac
exit 0
