---
description: QA를 별도 세션으로 돌려 빌드·lint·테스트 + 경계면 교차 검증을 수행하고 PASS/FIX/BLOCK로 보고한다.
---

`myarchive-qa` 에이전트를 별도 세션으로 호출해 myArchive를 검증한다. UI 작업과 분리된 깨끗한 컨텍스트에서 객관적으로 판정하기 위함이다.

## 실행

1. **Agent 도구로 `myarchive-qa` 호출** — `general-purpose` 타입, **model: opus**. 다음을 지시한다:
   - 정적 검증: `xcodegen generate` → `xcodebuild build`(시뮬레이터). destination 실패 시 `swiftc -typecheck`(iphonesimulator SDK)로 폴백.
   - `swiftlint`, `swiftformat --lint` 실행.
   - 단위 테스트(`myArchiveTests`) 실행.
   - **경계면 교차 검증**: 메타 ↔ Keychain ↔ UI 정합성(`passwordRef`/`valueRef` 저장·조회·삭제 키 규칙 일치, 삭제 시 양쪽 정리), `updatedAt ?? createdAt` 정렬·표기 일관성.
   - **보안 회귀**: 시크릿 평문 누출 경로(로그·스냅샷·DB·UserDefaults) 탐지, 블러·재마스킹·클립보드 만료·백그라운드 가림 동작.
2. **재시도 2회** — 결함 발견 시 ui/logic 수정본을 받아 최대 2회까지 재검증한다. 2회 후에도 남으면 사람 확인을 요청한다.

## 보고

- **PASS** — 모든 검증 통과. 변경 진행 가능.
- **FIX** — 수정 가능한 결함. 모듈별 `판정 / 사유 / 재현 / 수정 지시`로 정리.
- **BLOCK** — 보안·데이터 손실 위험. 머지·푸시 중단하고 즉시 보고.

판정은 주관이 아니라 PRD/Design.md 명세 대조로 내린다.
