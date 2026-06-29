<!--
  PR 본문 톤 가이드: docs/PR-writing-guide.md
  - 한 줄 요약 먼저 → 변경 사항은 "무엇을 / 왜 / 어떻게 쓰는지" 순
  - 프레임워크·API 이름 나열만 있는 줄 금지 (한 줄 풀이 필수)
  - 자동 리뷰 결과는 표로 정리
  - base 브랜치는 main (단일 통합 브랜치)
-->

## 관련 이슈

closes #

## 한 줄 요약

<!-- 이 PR이 무엇을 하는지 한 문장 -->

## 변경 사항

<!-- API 이름 나열 대신 "무엇을 / 왜 / 어떻게 쓰는지" 순으로 평이한 한국어. UI / Logic / 문서로 묶으면 좋다 -->
- 

## 직접 확인하는 법

<!-- 앱(시뮬레이터)에서 확인할 항목만. xcodegen generate / xcodebuild 같은 범용 명령 블록은 넣지 않는다 (docs/PR-writing-guide.md). 이 변경에만 필요한 특수 절차가 있을 때만 적는다. -->

- [ ] 

## 테스트

- [ ] SwiftLint 경고/에러 없음 · 빌드(xcodebuild) 통과
- [ ] `xcodebuild test`(또는 swiftc 타입체크 폴백) 통과 — 신규 로직(`myArchive/Services/`·`myArchive/ViewModels/`·`myArchive/Models/`)에 테스트 누락 없음 (`docs/TESTING.md` 우선순위 기준)
- [ ] 라이트 모드 표시 확인 (v1은 라이트 전용)
- [ ] 보안 도메인 규칙 확인 — 시크릿 평문 누출 없음(방식 B), 해당 시 마스킹/복사 만료/잠금 동작
- [ ] 주요 플로우 직접 테스트

## 스크린샷 (UI 변경 시)

| Before | After |
|--------|-------|
|  |  |

## 리뷰어 참고사항

<!-- 리뷰어가 알아야 할 사항, 주의점 -->
