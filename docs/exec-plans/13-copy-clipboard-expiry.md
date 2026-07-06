# 13 필드별 복사 + 클립보드 만료

- 이슈: #13  ·  PRD: F-4, F-8 (PRD 7.6)  ·  마일스톤: M5
- 상태: done

## 목표
상세 화면 각 필드(아이디/비밀번호/커스텀/URL/메모 전 범위)의 복사 버튼을 눌러 그 필드 값만 클립보드에 복사하고, 설정된 만료 시간(30/60/120초, 기본 60) 뒤 클립보드가 자동으로 비워진다. 복사 직후 버튼이 초록 체크로 1.3초간 전이하고, 하단에 '복사완료 · N초 후 자동 삭제' 토스트가 뜬다.

## 현황 (이미 있는 것 — 재사용)
- `Services/ClipboardService.copy(_:expiresInSeconds:)` — `UIPasteboard` 만료(`.expirationDate`) 설정까지 **구현 완료**. 그대로 호출만 하면 됨.
- `Models/AppSettings.swift` — `ClipboardExpiry`(30/60/120) enum + `SettingsKey.clipboardExpirySec`(기본 60) **존재**.
- `Views/Components/MAToast.swift` — `maToast(isPresented:title:subtitle:)` 모디파이어 **존재**(2.4s 자동 해제).
- `Views/Components/CopyButton.swift` — 38×38 스캐폴드만 있고 `action`은 빈 클로저, 초록 체크 전이는 "M5에서 추가"로 미구현.
- `ViewModels/DetailViewModel.swift` — `FieldItem.value`에 이미 **평문 값**(시크릿은 Keychain 조회분)이 들어 있음 → 복사 대상 값 확보됨.

## 작업 분해

### Logic (myarchive-logic)
- [ ] `DetailViewModel`에 복사 액션 추가 — `copy(item:expirySec:)`가 `ClipboardService.copy(item.value, expiresInSeconds: expirySec)` 호출.
- [ ] 토스트 문구 생성을 순수 함수/프로퍼티로 분리(예: `copyToastSubtitle(seconds:)` → "N초 후 자동 삭제"). View가 아니라 Logic에서 계산(테스트 대상).
- [ ] 마지막 복사 결과(라벨·만료초 등 토스트에 필요한 값)를 View가 관찰할 수 있게 노출. 시크릿 평문은 상태로 보관하지 않는다(복사 호출에만 사용).

### UI (myarchive-ui)
- [ ] `CopyButton` — 복사 직후 아이콘을 `doc.on.doc`(accent) → `checkmark`(success)로 1.3초간 전이 후 원복. 눌림 상태는 버튼 내부 `@State`로 관리, 실제 복사는 주입된 `action`이 수행.
- [ ] `DetailFieldRow` → `CredentialDetailView` — 복사 버튼을 실제 필드에 연결. `@AppStorage(SettingsKey.clipboardExpirySec)`로 만료초를 읽어 VM `copy` 호출.
- [ ] 복사 성공 시 `maToast` 트리거 — title "복사완료", subtitle "N초 후 자동 삭제". 라벨 무관하게 title 고정.

### 검증 (myarchive-qa)
- [ ] `swiftc -typecheck` + SwiftLint + SwiftFormat --lint 통과.
- [ ] 단위 테스트: 토스트 subtitle 문구 생성(만료초 → 문자열) · `ClipboardExpiry` 매핑. `myArchiveTests`.
- [ ] 경계면 교차 검증: 복사값이 마스킹된 값이 아닌 평문인지, 시크릿 평문이 VM 상태에 잔존하지 않는지.
- [ ] 실기기 확인 핸드오프: (a) 만료 시간 경과 후 클립보드 비워짐, (b) 초록 체크 1.3s 전이, (c) 토스트 등장.

## 의존성
Logic(`copy` API·문구 함수) → UI(`CopyButton` 전이 + 상세 연결·토스트) → QA. `CopyButton`의 전이는 상세 연결과 독립이라 병행 가능.

## 완료 조건
- 각 필드가 **독립 복사**(묶음 복사 없음)되고, 복사한 값만 클립보드에 담긴다.
- 만료 시간(설정값) 경과 후 클립보드가 비워진다(실기기 확인).
- 복사 직후 버튼 초록 체크(1.3s)와 '복사완료 · N초 후 자동 삭제' 토스트가 동작한다.
- 시크릿 평문이 로그·상태·문서 어디에도 남지 않는다(방식 B 준수).
- 관련 단위 테스트 통과.

## 진행 로그
- DetailViewModel: copy(item:expirySec:) + copyToastSubtitle(seconds:) 추가
- CopyButton: @State isCopied + 1.3s 체크 전이 구현
- CredentialDetailView: @AppStorage clipboardExpirySec + lastExpirySec 캡처 + maToast 트리거 + DetailFieldRow onCopy 연결
- myArchiveTests/DetailViewModelTests.swift: testCopyToastSubtitle / testClipboardExpiryMapping / testClipboardExpiryLabel 추가
- typecheck PASS · swiftlint PASS · swiftformat PASS
