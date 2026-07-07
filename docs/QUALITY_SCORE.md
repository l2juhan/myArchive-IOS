# QUALITY_SCORE — 품질 등급 추적

`/quality`가 관리한다. 동기화 대상이 아니다(코드 변경마다 갱신하지 않음). PR 전 `/quality`가 재평가하고 기준 미달이면 개선 후 진행한다.

기준은 `docs/swift-code-quality.md`(가독성·예측성·응집도·결합도) + 보안(시크릿 격리)·디자인 충실도.

## 등급표

| 축 | 등급(A~F) | 비고 |
| --- | --- | --- |
| 가독성 | A | MARK 구획 + Design.md 절 참조 주석. `sectionHeader`/`card`/`emptyState`/`noResultState` 등 의도 드러나는 이름 |
| 예측성 | A | `toggleFavorite`가 이름대로 `isFavorite`만 변경(updatedAt 불변). `filtered`/`sections` 순수 계산 프로퍼티 |
| 응집도 | A | 목록 화면은 `CredentialListView`, 행은 `CredentialRow`로 분리. `HeaderHeightKey`는 파일-private |
| 결합도 | A- | UI 표시 / 정렬·시간은 `CredentialSorter`·`RelativeTime`에 위임. 별 토글 `modelContext.save`만 View에서(단순 플래그, 허용) |
| 보안(시크릿 격리) | A | 목록은 serviceName/타임스탬프만 표시. 시크릿·passwordRef 미노출. 누출 0 |
| 디자인 충실도 | A | Design.md 2.2 / 스크린샷 02 픽셀 재현. 토큰 경유(하드코딩 없음) |
| 빌드/lint/테스트 | A | 실기기 빌드 green · typecheck 0 · SwiftLint 0 · SwiftFormat 적용. (UI라 단위 테스트 우선순위 낮음 — TESTING.md) |

## 이력

- 2026-07-07 — **#17 단위 테스트 보강** 평가(테스트 3파일: `KeychainServiceTests` 신규 + `CredentialSorterTests`·`DetailViewModelTests` 보강). 전 축 A~A- 유지, BLOCK 없음. **가독성** A(MARK 구획 + PRD 절 참조 주석, `setOrSkip`/`makeKey`/`makeViewModel` 의도 드러나는 헬퍼) · **예측성** A(값 계약 단정, 부작용 없음) · **응집도** A(대상별 파일 분리) · **결합도** A(순수 로직·값 계약만 검증, UI 미접촉) · **보안** A(시크릿 더미만, 실 사용자 값 0, `touchedKeys`+tearDown로 Keychain 잔여 0) · **빌드/lint/테스트** A(typecheck error0/warning0 · SwiftLint 0 · SwiftFormat 적용; 실기기 실행·Keychain 라운드트립은 XCTSkip host 가드로 사용자 핸드오프). 정직성: `CredentialSorter` tie-break 미구현 사실을 과단정 없이 집합 검증 + 주석으로 기록((c) 결정).
- 2026-07-02 — **#2 메인 목록 화면** 첫 기능 PR 평가. 전 축 A~A-, 기준 미달 없음(BLOCK 없음). 대상: `CredentialListView`·`CredentialRow`·`MAType`(토큰 4종 추가). QA: typecheck/SwiftLint 0·경계면 PASS. 실기기 빌드 BUILD SUCCEEDED. 참고: 첫 실행 CoreData "Application Support 없음→자동복구 성공" 로그는 무해(버그 아님).
- (최초 평가 전) — 하네스 구축 단계. 앱 골격 typecheck 통과 · SwiftLint 클린 · SwiftFormat 적용 상태.
