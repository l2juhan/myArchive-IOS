#!/bin/bash
# structure-check — 디렉터리 규칙·레이어 배치 제약 검증.
# 통과 시 exit 0. 위반(BLOCK)이 있으면 비0으로 종료. 경고(WARN)는 보고만 하고 exit code에 반영하지 않는다.
# 검증 항목:
#   1) Views/가 시크릿을 직접 다루지 않음 — KeychainService.get/set 직접 호출 금지(경계 분리, 경고)
#   2) 디자인 토큰 하드코딩 — Views/에서 Color(hex:) 과다 사용 점검(MAColor 경유 권장, 경고)
#   3) 필수 디렉터리 존재(App/DesignSystem/Models/Services/ViewModels/Views/Resources)
#   4) 시크릿 평문 print 금지 — myArchive/ 전체에서 print( 안에 password/secret 포함 라인(BLOCK)
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

SRC="myArchive"
VIEWS="$SRC/Views"
fail=0

warn() { echo "[structure][경고] $1" >&2; }
err()  { echo "[structure][위반] $1" >&2; fail=1; }

# (1) Views/는 Keychain 시크릿을 직접 호출하지 않는다 (경고)
if [ -d "$VIEWS" ]; then
  hits=$(grep -rnE 'KeychainService\.(get|set)\(' "$VIEWS" 2>/dev/null)
  if [ -n "$hits" ]; then
    warn "Views/에서 KeychainService.get/set 직접 호출 발견 — 시크릿 처리는 ViewModel(logic) 경유 권장:"
    echo "$hits" >&2
  fi
fi

# (2) 디자인 토큰 하드코딩 — Views/에서 Color(hex:) 과다 사용 (경고, 임계치 5)
if [ -d "$VIEWS" ]; then
  hex_count=$(grep -rhoE 'Color\(hex:' "$VIEWS" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$hex_count" -gt 5 ]; then
    warn "Views/에서 Color(hex:) 직접 사용 ${hex_count}건 — MAColor 토큰 경유 권장."
  fi
fi

# (3) 필수 디렉터리 존재 (위반)
for d in App DesignSystem Models Services ViewModels Views Resources; do
  if [ ! -d "$SRC/$d" ]; then
    err "필수 디렉터리 누락: $SRC/$d"
  fi
done

# (4) 시크릿 평문 print 금지 — myArchive/ 전체 (위반)
if [ -d "$SRC" ]; then
  secret_prints=$(grep -rnE 'print\([^)]*([Pp]assword|[Ss]ecret)' "$SRC" 2>/dev/null)
  if [ -n "$secret_prints" ]; then
    err "시크릿 평문 print 발견 — 시크릿은 로그에 남기지 않는다:"
    echo "$secret_prints" >&2
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "[structure] OK — 구조 규칙 위반 없음."
fi
exit "$fail"
