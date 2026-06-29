#!/bin/bash
# PostToolUse 훅 — edit 시점 게이트.
# Edit/Write 직후 호출된다. 변경된 .swift 파일에 SwiftFormat을 적용하고 SwiftLint 자동교정을 돌린다.
# 도구 미설치 시 graceful skip(차단하지 않음). stdin으로 훅 JSON을 받는다.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

payload=$(cat)
# tool_input.file_path 추출 (jq 있으면 jq, 없으면 python3)
if command -v jq >/dev/null 2>&1; then
  file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')
else
  file=$(printf '%s' "$payload" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
fi

[ -z "$file" ] && exit 0
case "$file" in
  *.swift) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

if command -v swiftformat >/dev/null 2>&1; then
  swiftformat "$file" --quiet 2>/dev/null
fi
if command -v swiftlint >/dev/null 2>&1; then
  swiftlint lint --fix --quiet --path "$file" 2>/dev/null
fi
exit 0
