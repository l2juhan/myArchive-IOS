#!/bin/bash
# PostToolUse 훅 — edit 시점 게이트.
# Edit/Write 직후 호출된다. 변경된 .swift 파일에 SwiftFormat을 적용하고 SwiftLint 자동교정을 돌린다.
# Write로 새 .swift 소스 파일이 추가되면 xcodegen generate를 실행해 .xcodeproj를 갱신한다.
# 도구 미설치 시 graceful skip(차단하지 않음). stdin으로 훅 JSON을 받는다.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

payload=$(cat)
# tool_input.file_path 추출 (jq 있으면 jq, 없으면 python3)
if command -v jq >/dev/null 2>&1; then
  file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')
  tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // empty')
else
  file=$(printf '%s' "$payload" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))' 2>/dev/null)
  tool_name=$(printf '%s' "$payload" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null)
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

# Write로 myArchive 소스 경로에 새 .swift 파일이 생성되면 .xcodeproj를 재생성한다.
# Edit는 기존 파일 수정이므로 Xcode가 이미 추적 중 — xcodegen 불필요.
if [ "$tool_name" = "Write" ] && command -v xcodegen >/dev/null 2>&1; then
  src_dir="${CLAUDE_PROJECT_DIR}/myArchive"
  case "$file" in
    "${src_dir}/"*.swift)
      xcodegen generate 2>/dev/null || true
      ;;
  esac
fi

exit 0
