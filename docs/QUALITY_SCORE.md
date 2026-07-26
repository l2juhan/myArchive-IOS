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

- 2026-07-26 — **#35 시크릿 마스킹(블러) 상태의 눈 아이콘 제거** 평가. 대상: `CredentialDetailView.swift` `valueText`의 `.secret` 케이스에서 `.overlay(alignment: .trailing)` 눈 아이콘 블록 삭제(9줄 → 1줄, doc 주석 동기화). 전 축 A 유지, BLOCK 없음. **가독성** A(삭제만으로 분기가 단순해짐, doc 주석도 "눈 힌트"→"탭 해제"로 실제 동작과 재일치) · **예측성** A(`.blur`/`.animation`/`onTapGesture` reveal 트리거 무변경 — 표시 힌트만 제거, 상태 전이 로직 불변) · **응집도** A(단일 파일 단일 케이스 내부 삭제, 다른 케이스·컴포넌트 영향 없음) · **결합도** A(순수 UI 표시 변경, Logic/ViewModel 경계 접촉 없음) · **보안** A(시크릿 평문 노출 없음 — 블러·탭 해제·재마스킹 보안 동작 무변경) · **디자인 충실도** A(이슈 #35 요구사항대로 블러만으로 마스킹 힌트, 눈 아이콘 제거) · **빌드/lint/테스트** A(typecheck 0 · SwiftLint 0 · SwiftFormat 클린 — QA 확인 완료, 실기기 탭 reveal 시각 확인은 사용자 핸드오프).
- 2026-07-22 — **#34 시크릿 값 폰트 통일** 평가(모노스페이스 → 시스템 폰트). 대상: `MAType.secretValue` 토큰 1곳(`design: .monospaced` 제거), `Design.md` 1.3·`DESIGN_SYSTEM.md` 동기화. 전 축 A 유지, BLOCK 없음. **가독성** A(토큰 주석이 변경 의도를 그대로 반영) · **예측성** A(폰트 상수만 변경, 마스킹·복사·클립보드 만료 등 보안 동작 무변경) · **응집도** A(단일 토큰 정의만 수정, 호출부 4곳 무변경) · **결합도** A(DesignSystem 레이어 내부 변경, UI/Logic 경계 영향 없음) · **보안** A(시크릿 평문 노출 없음 — 표시 폰트만 변경, 블러/터치 해제 로직 불변) · **디자인 충실도** A(Design.md 1.3 확정값을 함께 갱신해 코드·문서 재동기화) · **빌드/lint/테스트** A(typecheck 0 · SwiftLint 0 · SwiftFormat 클린 · 실기기 시각 확인 완료).
- 2026-07-07 — **#17 단위 테스트 보강** 평가(테스트 3파일: `KeychainServiceTests` 신규 + `CredentialSorterTests`·`DetailViewModelTests` 보강). 전 축 A~A- 유지, BLOCK 없음. **가독성** A(MARK 구획 + PRD 절 참조 주석, `setOrSkip`/`makeKey`/`makeViewModel` 의도 드러나는 헬퍼) · **예측성** A(값 계약 단정, 부작용 없음) · **응집도** A(대상별 파일 분리) · **결합도** A(순수 로직·값 계약만 검증, UI 미접촉) · **보안** A(시크릿 더미만, 실 사용자 값 0, `touchedKeys`+tearDown로 Keychain 잔여 0) · **빌드/lint/테스트** A(typecheck error0/warning0 · SwiftLint 0 · SwiftFormat 적용; 실기기 실행·Keychain 라운드트립은 XCTSkip host 가드로 사용자 핸드오프). 정직성: `CredentialSorter` tie-break 미구현 사실을 과단정 없이 집합 검증 + 주석으로 기록((c) 결정).
- 2026-07-02 — **#2 메인 목록 화면** 첫 기능 PR 평가. 전 축 A~A-, 기준 미달 없음(BLOCK 없음). 대상: `CredentialListView`·`CredentialRow`·`MAType`(토큰 4종 추가). QA: typecheck/SwiftLint 0·경계면 PASS. 실기기 빌드 BUILD SUCCEEDED. 참고: 첫 실행 CoreData "Application Support 없음→자동복구 성공" 로그는 무해(버그 아님).
- (최초 평가 전) — 하네스 구축 단계. 앱 골격 typecheck 통과 · SwiftLint 클린 · SwiftFormat 적용 상태.
