# feedback-log — 피드백 루프 기록

harness-feedback 스킬과 `/health`가 이 로그를 관리한다. 반복되는 교정·drift, 하네스 점검에서 발견한 문제를 기록한다. 작업 브랜치에서 바로 고치지 않고 여기에 모았다가 별도로 정비한다.

형식:
```
## [YYYY-MM-DD] 제목
- 유형: drift | 반복 교정 | health 발견 | 규칙 제안
- 관찰: 무엇이 반복/문제인가
- 제안: 규칙/훅/스킬/문서 개선안
- 상태: open | applied | wontfix
```

---

## [2026-06-29] CI 구조검사: 빈 디렉터리 미추적으로 로컬↔CI 불일치
- 유형: drift (로컬 통과, CI 실패)
- 관찰: `structure-check.sh`가 로컬에선 통과했으나 CI에서 "필수 디렉터리 누락: myArchive/ViewModels"로 exit 1. git이 빈 디렉터리를 추적하지 않아 CI 체크아웃에 ViewModels가 없었음. PR #1 머지가 mergeStateStatus=UNSTABLE로 거절됨.
- 제안: 필수 레이어 디렉터리는 `.gitkeep`으로 추적 유지(적용함). 향후 빈 레이어 추가 시 동일 처리. 구조검사가 "로컬에만 있는 디렉터리"를 신뢰하지 않도록, 필요하면 git 추적 기준으로 점검하는 방안 검토.
- 상태: applied

## [2026-06-29] 하네스 초기 구축
- 유형: 규칙 제안
- 관찰: 로컬 Xcode 환경에서 `xcodebuild`가 시뮬레이터 destination을 간헐적으로 enumerate하지 못함(CoreSimulatorService 재시작으로 복구). iOS 26.5 device 플랫폼 미설치 상태.
- 제안: QA 빌드 검증은 destination 실패 시 `swiftc -typecheck`(iphonesimulator SDK)로 폴백한다. myarchive-qa 정의에 반영됨.
- 상태: applied
