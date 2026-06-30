# TESTING — 단위 테스트 가이드

XCTest로 myArchive의 **보안·정합성·정렬/시간** 로직을 검증한다. 테스트 타깃은 `myArchiveTests`다. UI는 표시만 하므로(ARCHITECTURE 레이어), 테스트는 `Services/`·`ViewModels/` 로직에 집중한다.

## 우선순위

> 보안·정합성 > 정렬/시간 > UI. 위에서부터 채운다.

1. **보안·정합성 (필수)** — 시크릿 격리, 메타↔Keychain 동시 정리. 깨지면 평문 누출·고아 데이터.
2. **정렬/시간 (중요)** — `CredentialSorter`, `RelativeTime` 경계값.
3. **마스킹 상태** — 22초 만료·이탈 재마스킹.
4. **UI (낮음)** — 필요 시 스냅샷·`@Observable` 상태 전이만.

## 테스트 대상

### KeychainService (보안)
- 저장 → 조회 시 동일 값 반환.
- 같은 키 재저장 시 갱신(중복 추가 아님).
- 삭제 후 조회 시 `nil`(또는 not-found 에러), 평문 추측 금지.
- 키 규칙: `passwordRef(id) == "pw_\(id)"`, `valueRef(id) == "cf_\(id)"`.
- OSStatus는 타입화된 에러로 전파(삼키지 않음).

### CredentialSorter (정렬/섹션)
- 즐겨찾기 우선(`isFavorite == true`가 항상 앞).
- 같은 그룹 내 `activityDate(= updatedAt ?? createdAt)` 내림차순.
- 동일 시각이면 `serviceName` 오름차순(안정 정렬).
- 검색 시 섹션 분리(즐겨찾기/일반)와 0건 처리.

### RelativeTime (상대시간 경계값)
- 0~59초 → "방금 전".
- 60초~59분 → "N분 전".
- 60분~23시간 → "N시간 전".
- 24시간~6일 → "N일 전".
- 7일 이상 → "N주 전"(또는 날짜 표기). **경계 직전/직후 양쪽**을 검증한다.

### 마스킹 상태 (ViewModel)
- 터치 해제는 단방향(토글 아님): 한 번 해제하면 다시 같은 동작으로 마스킹되지 않는다.
- 약 22초 경과 시 자동 재마스킹.
- 화면 이탈(scenePhase 비활성 / 재진입) 시 모든 필드 재마스킹.

### 정합성 (KeychainService + ModelContext)
- 계정 삭제: SwiftData 제거 + `passwordRef` 및 모든 `valueRef` Keychain 삭제.
- 커스텀 필드 삭제: 메타 제거 + `valueRef` Keychain 삭제.
- 조회 실패(메타 있음·Keychain 없음): 사용자 안내 경로로 흐르고 평문 추측 안 함.

## 실행 — **실기기 전용 (시뮬레이터 금지)**

> 이 프로젝트는 **시뮬레이터로 테스트하지 않는다**(CLAUDE.md "테스트·빌드 정책"). 단위 테스트도 실기기에서 돌린다. `platform=iOS Simulator` destination을 쓰지 않는다.

XcodeGen으로 프로젝트를 먼저 생성한 뒤, **연결된 실기기** destination으로 `xcodebuild test`를 실행한다(SPM `swift test`는 iOS 앱 타깃이라 사용 불가). 서명(`DEVELOPMENT_TEAM`)이 설정돼 있어야 한다.

```bash
xcodegen generate

# 연결된 기기 id 확인
xcodebuild -showdestinations -project myArchive.xcodeproj -scheme myArchive
# → platform:iOS, id:00008XXX-... 인 항목(시뮬레이터 아님)을 고른다

xcodebuild test \
  -project myArchive.xcodeproj \
  -scheme myArchive \
  -destination 'platform=iOS,id=<연결된-기기-id>'   # 또는 'generic/platform=iOS'
```

- 기기가 연결돼 있지 않으면 테스트는 **보류**한다 — 시뮬레이터로 대체하지 않는다.
- **컴파일 정합성만** 빠르게 보려면(기기 없이) 시뮬레이터 SDK path로 **타입체크까지만** 한다(빌드/실행 아님):

```bash
swiftc -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -target arm64-apple-ios17.0-simulator -typecheck <파일들>
```

- 화면 시각 확인은 Xcode Canvas `#Preview`를 보조로 쓴다.

## 예시

### KeychainService — 저장/조회/삭제 라운드트립

```swift
import XCTest
@testable import myArchive

final class KeychainServiceTests: XCTestCase {
    private let key = "pw_test_\(UUID().uuidString)"

    override func tearDown() {
        try? KeychainService.delete(key)
        super.tearDown()
    }

    func test_save_then_read_returns_same_value() throws {
        try KeychainService.save("s3cret!", for: key)
        XCTAssertEqual(try KeychainService.read(key), "s3cret!")
    }

    func test_resave_updates_not_duplicates() throws {
        try KeychainService.save("old", for: key)
        try KeychainService.save("new", for: key)
        XCTAssertEqual(try KeychainService.read(key), "new")
    }

    func test_delete_removes_value() throws {
        try KeychainService.save("x", for: key)
        try KeychainService.delete(key)
        XCTAssertNil(try KeychainService.read(key)) // 평문 추측 금지
    }
}
```

### RelativeTime — 경계값

```swift
func test_relativeTime_boundaries() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    func at(_ secAgo: TimeInterval) -> String {
        RelativeTime.string(from: now.addingTimeInterval(-secAgo), now: now)
    }
    XCTAssertEqual(at(0),    "방금 전")
    XCTAssertEqual(at(59),   "방금 전")
    XCTAssertEqual(at(60),   "1분 전")
    XCTAssertEqual(at(3599), "59분 전")
    XCTAssertEqual(at(3600), "1시간 전")
    XCTAssertEqual(at(86_400), "1일 전")
}
```

> 시그니처(`save(_:for:)`, `read(_:)`, `RelativeTime.string(from:now:)`)는 구현에 맞춰 조정한다. 시간 함수는 `now`를 주입받아 결정적으로 테스트한다(`Date()` 직접 호출 금지).
