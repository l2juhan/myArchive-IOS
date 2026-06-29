# swift-code-quality — 코드 품질 기준

myArchive 코드는 네 축으로 평가한다: **가독성 · 예측성 · 응집도 · 결합도**. 여기에 myArchive 특화 게이트 둘을 더한다: **보안(시크릿 격리)** 과 **디자인 충실도**. `/quality`는 이 문서를 기준으로 `docs/QUALITY_SCORE.md`를 평가한다(A~F + BLOCK 항목).

SwiftLint(`.swiftlint.yml`)·SwiftFormat(`.swiftformat`)이 기계적으로 강제하는 것은 자동 교정(edit 시점 게이트)으로 처리하고, 이 문서는 **사람·LLM의 판단이 필요한** 기준을 다룬다.

---

## 1. 가독성

코드를 위에서 아래로 읽으며 의도가 드러나야 한다.

- 이름이 역할을 말한다. `data`/`tmp`/`flag` 금지. 토큰은 `MAColor`/`MAType`(ARCHITECTURE 네이밍).
- 매직 값 금지: 22초·60초·"방금 전" 같은 상수는 명명 상수로.
- 함수는 한 가지 일. `function_body_length` warning 60줄(lint와 일치).

```swift
// 나쁨 — 의도 불명, 매직 넘버
if Date().timeIntervalSince(d) > 22 { v = mask(v) }

// 좋음
private let revealTimeout: TimeInterval = 22  // PRD 7.5 자동 재마스킹
if now.timeIntervalSince(revealedAt) > revealTimeout { remask(field) }
```

## 2. 예측성

같은 호출은 같은 결과를. 숨은 부작용 금지.

- 순수 로직(`CredentialSorter`·`RelativeTime`)은 입력만으로 출력 결정. `Date()`를 내부에서 직접 부르지 말고 `now`를 주입(테스트 가능, TESTING.md).
- 에러는 삼키지 않는다. Keychain OSStatus는 타입화된 에러로 전파(ARCHITECTURE 6).
- 마스킹 해제는 **단방향**(토글 아님) — 명세된 상태 전이만 일어난다(PRD 7.5).

```swift
// 나쁨 — 실패를 평문 추측으로 가림
func read(_ k: String) -> String { (try? keychain.read(k)) ?? "" }

// 좋음 — 실패를 호출자에게 알림
func read(_ k: String) throws -> String?  // 없으면 nil, 오류는 throw
```

## 3. 응집도

함께 바뀌는 것은 함께 둔다.

- 레이어 책임 고정: View는 표시, ViewModel은 화면 상태·조율, Service는 값 처리·보안·영속(ARCHITECTURE 레이어).
- 한 서비스 = 한 관심사: `KeychainService`(시크릿)·`ClipboardService`(만료 복사)·`CredentialSorter`(정렬)·`RelativeTime`(표기)를 섞지 않는다.
- `type_body_length` warning 300줄 — 비대해지면 책임이 섞인 신호.

```swift
// 나쁨 — ViewModel이 Keychain·정렬·시간 표기를 직접 다룸(책임 혼재)
// 좋음 — ViewModel은 Service를 조율만:
sorted = CredentialSorter.sections(creds, query: query, mode: sortMode)
```

## 4. 결합도

모듈 간 의존을 얇게.

- UI → Logic 단방향. View는 Logic이 준 API만 호출하고 시크릿 값을 직접 보유·가공하지 않는다(folder-structure 경계).
- 휘발 UI 상태(마스킹 해제·토스트·드래프트)는 ViewModel/`@State`, 영속 상태는 SwiftData/UserDefaults — 소유권을 섞지 않는다(ARCHITECTURE 4).
- 구체 타입 대신 좁은 입력. 정렬 함수는 `[Credential]`만 받고 `ModelContext`에 의존하지 않는다.
- 외부 라이브러리 0 — Apple 표준 프레임워크만(CLAUDE.md).

---

## 5. 보안 — 시크릿 격리 (BLOCK 게이트)

> **평문 누출 0이 통과 기준.** 하나라도 위반하면 BLOCK(등급과 무관하게 머지 차단).

- 비밀번호·커스텀 값 평문은 **Keychain에만**. SwiftData·UserDefaults·로그·에러 메시지에 평문 금지(ARCHITECTURE 1, PRD 7.2).
- 메타에는 참조 키(`pw_…`/`cf_…`)만.
- `print`/로그에 시크릿 변수 금지. 디버그 출력도 마스킹.
- 강제 언래핑 경계: `force_unwrapping` opt-in(lint) — 시크릿 경로에서 크래시·노출 방지.

```swift
// 나쁨 — 평문이 영속 DB로
credential.password = plain          // SwiftData에 평문 (금지)
// 좋음 — 참조만 메타에, 값은 Keychain
credential.passwordRef = KeychainService.passwordRef(credential.id)
try KeychainService.save(plain, for: credential.passwordRef)
```

## 6. 디자인 충실도

- 색·타이포·간격·라운드·모션은 **토큰만** 사용(`MAColor`/`MAType`/`MASpacing`/`MARadius`/`MAMotion`). 하드코딩(`Color(hex:)`, `.font(.system(size: 17))`, `.padding(16)`) 금지 — `DESIGN_SYSTEM.md` ↔ `Design.md` 단일 소스.
- 라이트 모드 전용 가정 유지(PRD 6.4).

```swift
// 나쁨
.foregroundStyle(Color(red: 0.3, green: 0.3, blue: 0.8)).padding(16)
// 좋음
.foregroundStyle(MAColor.accent).padding(MASpacing.md)
```

---

## /quality 평가 방식

`/quality`는 위 1~6축을 코드 변경분에 대해 평가해 `QUALITY_SCORE.md` 등급표를 갱신한다.
- 가독성·예측성·응집도·결합도·디자인 충실도: A~F.
- 보안(시크릿 격리): 평문 누출 0이면 통과, 아니면 **BLOCK**.
- 빌드/lint/테스트 green 필수.
기준 미달이면 개선 후 PR을 진행한다(CLAUDE.md 승인 게이트).
